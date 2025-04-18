---
title: TiDB Lightning 错误处理功能
summary: 介绍了如何解决导入数据过程中的类型转换和冲突错误。
---

# TiDB Lightning 错误处理功能

从 TiDB 5.4.0 开始，你可以配置 TiDB Lightning 以跳过诸如无效类型转换、唯一键冲突等错误，让导入任务持续进行，就如同出现错误的行数据不存在一样。你可以依据生成的报告，手动修复这些错误。该功能适用于以下场景：

- 要导入的数据有少许错误
- 手动定位错误比较困难
- 如果遇到错误就重启 TiDB Lightning，代价太大

本文介绍 TiDB Lightning 错误处理功能涉及的错误种类、查询方法，并提供了一个示例。本文涉及的配置项如下：

- `lightning.max-error`：类型错误的容忍阈值
- `conflict.strategy`、`conflict.threshold`、`conflict.max-record-rows`：数据冲突错误的相关配置
- `tikv-importer.duplicate-resolution`（从 v8.0.0 开始已被废弃，并将在未来版本中被移除）：物理导入模式下的冲突处理配置
- `lightning.task-info-schema-name`：冲突数据存储的库名

相关配置项详情请参考 [TiDB Lightning 任务配置](/tidb-lightning/tidb-lightning-configuration.md#tidb-lightning-任务配置)。

## 类型错误 (Type error)

你可以通过修改配置项 `lightning.max-error` 来增加数据类型相关的容错数量。如果设置为 *N*，那么 TiDB Lightning 允许数据源中出现 *N* 个类型错误，而且会跳过这些错误继续导入，一旦超过这个错误数就会退出。默认值为 0，表示不允许出现错误。

这些错误会被记录到数据库中。在导入完成后，你可以查看数据库中的数据，手动进行处理。请参见[错误报告](#错误报告)。

{{< copyable "" >}}

```toml
[lightning]
max-error = 0
```

该配置对下列错误有效：

* 无效值。例如：在 INT 列设置了 `'Text'`
* 数字溢出。例如：在 TINYINT 列设置了 500
* 字符串溢出。例如: 在 VARCHAR(5) 列中设置了`'非常长的文字'`
* 零日期时间，如 `'0000-00-00'` 和 `'2021-12-00'`
* 在 NOT NULL 列中设置了 NULL
* 生成的列表达式求值失败
* 列计数不匹配。行中数值的数量和列的数量不一致
* 其他 SQL 错误

下列错误是致命错误，不能通过配置 `lightning.max-error` 跳过：

* 原始 CSV、SQL 或者 Parquet 文件中的语法错误，例如未闭合的引号
* I/O、网络、或系统权限错误

## 冲突错误 (Conflict error)

你可以通过修改配置项 [`conflict.threshold`](/tidb-lightning/tidb-lightning-configuration.md#tidb-lightning-任务配置) 来增加冲突错误相关的容错数量。如果设置为 *N*，那么 TiDB Lightning 允许数据源中出现 *N* 个冲突错误，而且会跳过这些错误继续导入，一旦超过这个错误数就会退出。在逻辑导入模式或者物理导入模式下，不同的场景会产生冲突错误，你可以参考对应导入模式的“冲突检测”文档。该配置项默认值为 `10000`，意味着能容忍 10000 个错误。

这些错误会被记录到数据库中。在导入完成后，你可以查看数据库中的数据，手动进行处理。请参见[错误报告](#错误报告)。

## 错误报告

如果 TiDB Lightning 在运行过程中收集到报错的记录，则在退出时会同时在终端和日志中输出各个类型报错数量的统计信息。

* 输出在终端的报错统计如下表所示：

    | # | ERROR TYPE | ERROR COUNT | ERROR DATA TABLE |
    | - | --- | --- | ------ |
    | 1 | Data Type | 1000 | `lightning_task_info`.`type_error_v1` |

* 输出在 TiDB Lightning 的 log 文件的结尾如下：

    ```shell
    [2022/03/13 05:33:57.736 +08:00] [WARN] [errormanager.go:459] ["Detect 1000 data type errors in total, please refer to table `lightning_task_info`.`type_error_v1` for more details"]
    ```

所有错误都会写入下游 TiDB 集群 `lightning_task_info` 数据库中的表中。在导入完成后，如果收集到报错的数据，你可以根据数据库中记录的内容，手动进行处理。

你可以使用 `lightning.task-info-schema-name` 配置更改数据库名称。

{{< copyable "" >}}

```toml
[lightning]
task-info-schema-name = 'lightning_task_info'
```

在此数据库中，TiDB Lightning 创建了 3 个表和 1 个视图：

```sql
CREATE TABLE type_error_v1 (
    task_id     bigint NOT NULL,
    create_time datetime(6) NOT NULL DEFAULT now(6),
    table_name  varchar(261) NOT NULL,
    path        varchar(2048) NOT NULL,
    offset      bigint NOT NULL,
    error       text NOT NULL,
    row_data    text NOT NULL
);
CREATE TABLE conflict_error_v3 (
    task_id     bigint NOT NULL,
    create_time datetime(6) NOT NULL DEFAULT now(6),
    table_name  varchar(261) NOT NULL,
    index_name  varchar(128) NOT NULL,
    key_data    text NOT NULL,
    row_data    text NOT NULL,
    raw_key     mediumblob NOT NULL,
    raw_value   mediumblob NOT NULL,
    raw_handle  mediumblob NOT NULL,
    raw_row     mediumblob NOT NULL,
    kv_type     tinyint NOT NULL,
    INDEX (task_id, table_name),
    INDEX (index_name),
    INDEX (table_name, index_name),
    INDEX (kv_type)
);
CREATE TABLE conflict_records (
    task_id     bigint NOT NULL,
    create_time datetime(6) NOT NULL DEFAULT now(6),
    table_name  varchar(261) NOT NULL,
    path        varchar(2048) NOT NULL,
    offset      bigint NOT NULL,
    error       text NOT NULL,
    row_id      bigint NOT NULL COMMENT 'the row id of the conflicted row',
    row_data    text NOT NULL COMMENT 'the row data of the conflicted row',
    KEY (task_id, table_name)
);
CREATE VIEW conflict_view AS
    SELECT 0 AS is_precheck_conflict, task_id, create_time, table_name, index_name, key_data, row_data, raw_key, raw_value, raw_handle, raw_row, kv_type, NULL AS path, NULL AS offset, NULL AS error, NULL AS row_id
    FROM conflict_error_v3
    UNION ALL
    SELECT 1 AS is_precheck_conflict, task_id, create_time, table_name, NULL AS index_name, NULL AS key_data, row_data, NULL AS raw_key, NULL AS raw_value, NULL AS raw_handle, NULL AS raw_row, NULL AS kv_type, path, offset, error, row_id
    FROM conflict_records;
```

`type_error_v1` 表记录由 `lightning.max-error` 配置项管理的所有[类型错误 (Type error)](#类型错误-type-error)。每个错误一行。

`conflict_error_v3` 表记录物理导入模式的 `conflict` 配置组的后置检测冲突错误，每对冲突占两行。

`conflict_records` 表记录逻辑导入模式和物理导入模式 `conflict` 配置组的前置检测冲突错误，每个错误占一行。

`conflict_view` 视图记录物理导入模式和逻辑导入模式 `conflict` 配置组的前置和后置检测冲突错误，是通过对 `conflict_error_v3` 表和 `conflict_records` 表进行 `UNION` 操作生成的。

| 列名     | 语法 | 类型 | 冲突 | 说明                                                                                                                         |
| ------------ | ------ | ---- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| task_id      | ✓      | ✓    | ✓        | 生成此错误的 TiDB Lightning 任务 ID                                            |
| create_time | ✓      | ✓    | ✓        | 记录错误的时间                                                                   |
| table_name   | ✓      | ✓    | ✓        | 包含错误的表的名称，格式为 ``'`db`.`tbl`'``                                                                |
| path         | ✓      | ✓    |          | 包含错误文件的路径                                                       |
| offset       | ✓      | ✓    |          | 文件中发现错误的字节位置                                         |
| error        | ✓      | ✓    |          | 错误信息                                                                                 |
| context      | ✓      |      |          | 围绕错误的文本                                                             |
| index_name   |        |      | ✓        | 冲突中唯一键的名称。主键冲突为 `'PRIMARY'`                    |
| key_data     |        |      | ✓        | 导致错误的行的格式化键句柄。该内容仅供人参考，机器不可读 |
| row_data     |        | ✓    | ✓        | 导致错误的格式化行数据。该内容仅供人参考，机器不可读          |
| raw_key      |        |      | ✓        | 冲突的 KV 对的键                                                           |
| raw_value    |        |      | ✓        | 冲突的 KV 对的值                                                            |
| raw_handle   |        |      | ✓        | 冲突行的行句柄                                                         |
| raw_row      |        |      | ✓        | 冲突行的编码值                                                       |

> **注意：**
>
> 错误报告记录的是文件偏移量，不是行号或列号，因为行号或列号的获取效率很低。你可以使用下列命令在字节位实现快速跳转（以 183 为例）：
>
> * shell：输出前面几行
>
>     ```shell
>     head -c 183 file.csv | tail
>     ```
>
> * shell，输出后面几行
>
>     ```shell
>     tail -c +183 file.csv | head
>     ```
>
> * vim：`:goto 183` 或 `183go`

## 示例

在该示例中，我们准备了一个包含一些已知错误的数据源。以下是处理这些错误的具体步骤：

1. 准备数据库和表结构：

    {{< copyable "shell-regular" >}}

    ```sh
    mkdir example && cd example
    echo 'CREATE SCHEMA example;' > example-schema-create.sql
    echo 'CREATE TABLE t(a TINYINT PRIMARY KEY, b VARCHAR(12) NOT NULL UNIQUE);' > example.t-schema.sql
    ```

2. 准备数据：

    {{< copyable "shell-regular" >}}

    ```shell
    cat <<EOF > example.t.1.sql
        INSERT INTO t (a, b) VALUES
        (0, NULL),              -- 列不为空
        (1, 'one'),
        (2, 'two'),
        (40, 'forty'),          -- 与下面的 `40` 冲突
        (54, 'fifty-four'),     -- 与下面的 `'fifty-four'` 冲突
        (77, 'seventy-seven'),  -- 字符串长度超过 12 个字符
        (600, 'six hundred'),   -- 数字超出了 TINYINT 数据类型支持的范围
        (40, 'forty'),         -- 与上面的 `40` 冲突
        (42, 'fifty-four');     -- 与上面的 `'fifty-four'` 冲突
    EOF
    ```

3. 配置 TiDB Lightning，启用严格 SQL 模式，使用 Local 后端模式进行导入，通过替换解决重复项，并最多跳过 10 个错误：

    {{< copyable "shell-regular" >}}

    ```shell
    cat <<EOF > config.toml
        [lightning]
        max-error = 10
        [tikv-importer]
        backend = 'local'
        sorted-kv-dir = '/tmp/lightning-tmp/'
        [conflict]
        strategy = 'replace'
        [mydumper]
        data-source-dir = '.'
        [tidb]
        host = '127.0.0.1'
        port = 4000
        user = 'root'
        password = ''
        sql-mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE'
    EOF
    ```

4. 运行 TiDB Lightning。因为已跳过所有错误，该命令执行完会成功退出：

    {{< copyable "shell-regular" >}}

    ```shell
    tiup tidb-lightning -c config.toml
    ```

5. 验证导入的表仅包含两个正常行：

    ```sql
    $ mysql -u root -h 127.0.0.1 -P 4000 -e 'select * from example.t'
    +---+-----+
    | a | b   |
    +---+-----+
    | 1 | one |
    | 2 | two |
    +---+-----+
    ```

6. 检查 `type_error_v1` 表是否捕获了涉及类型转换的三行：

    ```sql
    $ mysql -u root -h 127.0.0.1 -P 4000 -e 'select * from lightning_task_info.type_error_v1;' -E
    *************************** 1. row ***************************
        task_id: 1635888701843303564
    create_time: 2021-11-02 21:31:42.620090
     table_name: `example`.`t`
           path: example.t.1.sql
         offset: 46
          error: failed to cast value as varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin for column `b` (#2): [table:1048]Column 'b' cannot be null
       row_data: (0,NULL)
    *************************** 2. row ***************************
        task_id: 1635888701843303564
    create_time: 2021-11-02 21:31:42.627496
     table_name: `example`.`t`
           path: example.t.1.sql
         offset: 183
          error: failed to cast value as varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin for column `b` (#2): [types:1406]Data Too Long, field len 12, data len 13
       row_data: (77,'seventy-seven')
    *************************** 3. row ***************************
        task_id: 1635888701843303564
    create_time: 2021-11-02 21:31:42.629929
     table_name: `example`.`t`
           path: example.t.1.sql
         offset: 253
          error: failed to cast value as tinyint for column `a` (#1): [types:1690]constant 600 overflows tinyint
       row_data: (600,'six hundred')
    ```

7. 检查 `conflict_error_v3` 表是否捕获了具有唯一键/主键冲突的四行：

    ```sql
    $ mysql -u root -h 127.0.0.1 -P 4000 -e 'select * from lightning_task_info.conflict_error_v3;' --binary-as-hex -E
    *************************** 1. row ***************************
        task_id: 1635888701843303564
    create_time: 2021-11-02 21:31:42.669601
     table_name: `example`.`t`
     index_name: PRIMARY
       key_data: 40
       row_data: (40, "forty")
        raw_key: 0x7480000000000000C15F728000000000000028
      raw_value: 0x800001000000020500666F727479
     raw_handle: 0x7480000000000000C15F728000000000000028
        raw_row: 0x800001000000020500666F727479
    *************************** 2. row ***************************
        task_id: 1635888701843303564
    create_time: 2021-11-02 21:31:42.674798
     table_name: `example`.`t`
     index_name: PRIMARY
       key_data: 40
       row_data: (40, "fourty")
        raw_key: 0x7480000000000000C15F728000000000000028
      raw_value: 0x800001000000020600666F75727479
     raw_handle: 0x7480000000000000C15F728000000000000028
        raw_row: 0x800001000000020600666F75727479
    *************************** 3. row ***************************
        task_id: 1635888701843303564
    create_time: 2021-11-02 21:31:42.680332
     table_name: `example`.`t`
     index_name: b
       key_data: 54
       row_data: (54, "fifty-four")
        raw_key: 0x7480000000000000C15F6980000000000000010166696674792D666FFF7572000000000000F9
      raw_value: 0x0000000000000036
     raw_handle: 0x7480000000000000C15F728000000000000036
        raw_row: 0x800001000000020A0066696674792D666F7572
    *************************** 4. row ***************************
        task_id: 1635888701843303564
    create_time: 2021-11-02 21:31:42.681073
     table_name: `example`.`t`
     index_name: b
       key_data: 42
       row_data: (42, "fifty-four")
        raw_key: 0x7480000000000000C15F6980000000000000010166696674792D666FFF7572000000000000F9
      raw_value: 0x000000000000002A
     raw_handle: 0x7480000000000000C15F72800000000000002A
        raw_row: 0x800001000000020A0066696674792D666F7572
    ```
