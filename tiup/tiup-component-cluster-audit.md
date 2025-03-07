---
title: tiup cluster audit
summary: tiup cluster audit 命令用于查看集群执行的历史命令和执行日志。若不填写 audit-id，则按时间倒序输出操作记录表格，包括 audit-id、命令执行时间和命令。若填写 audit-id，则查看指定的执行日志。选项 -h, --help 用于输出帮助信息。输出包括指定的执行日志或包含 ID、时间和命令的表格。
---

# tiup cluster audit

命令 `tiup cluster audit` 可以用于查看历史上对所有集群执行了什么命令，以及每个命令的执行日志。

## 语法

```shell
tiup cluster audit [audit-id] [flags]
```

- 若不填写 `[audit-id]` 则按时间倒序输出操作记录的表格，第一列为 audit-id
- 若填写 `[audit-id]` 则查看指定的 audit-id 的执行日志

## 选项

### -h, --help

- 输出帮助信息。
- 数据类型：`BOOLEAN`
- 该选项默认关闭，默认值为 `false`。在命令中添加该选项，并传入 `true` 值或不传值，均可开启此功能。

## 输出

- 若指定 `[audit-id]`，则输出对应的执行日志
- 若不指定 `[audit-id]` 则输出含有以下字段的表格：
    - ID：该条记录对应的 audit-id
    - Time：该条记录对应的命令执行时间
    - Command：该条记录对应的命令