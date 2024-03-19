---
title: TiDB 8.0.0 Release Notes
summary: 了解 TiDB 8.0.0 版本的新功能、兼容性变更、改进提升，以及错误修复。
---

# TiDB 8.0.0 Release Notes

发版日期：2024 年 x 月 x 日

TiDB 版本：8.0.0

试用链接：[快速体验](https://docs.pingcap.com/zh/tidb/v8.0/quick-start-with-tidb) | [下载离线包](https://cn.pingcap.com/product-community/?version=v8.0.0-DMR#version-list)

在 8.0.0 版本中，你可以获得以下关键特性：

<table>
<thead>
  <tr>
    <th>分类</th>
    <th>功能/增强</th>
    <th>描述</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td rowspan="4">可扩展性与性能</td>
    <td>支持拆分 PD 功能为微服务，提高可扩展性（实验特性）**tw@qiancai** <!--1553, 1558--></td>
    <td>Placement Driver (PD) 包含了多个确保 TiDB 集群能正常运行的关键模块。当集群的工作负载增加时，PD 中各模块的资源消耗也会随之增加，造成这些模块间功能的相互干扰，进而影响整个集群的服务质量。为了解决该问题，从 v8.0.0 起，TiDB 支持将 PD 的 TSO 和调度模块拆分成可独立部署的微服务，可以显著降低当集群规模扩大时模块间的互相影响。通过这种架构，TiDB 能够支持更大规模、更高负载的集群。
  </tr>
  <tr>
    <td><a href="https://docs.pingcap.com/zh/tidb/v8.0/system-variables#tidb_dml_type-从-v800-版本开始引入">用于处理更大事务的批量 DML 执行方式（实验特性）</a>**tw@Oreoxmt** <!--1694--></td>
    <td>大批量的 DML 任务，例如大规模的清理任务、连接或聚合，可能会消耗大量内存，并且在非常大的规模上受到限制。批量 DML (<code>tidb_dml_type = "bulk"</code>) 是一种新的 DML 类型，用于更高效地处理大批量 DML 任务，同时提供事务保证并减轻 OOM 问题。该功能与用于数据加载的导入、加载和恢复操作不同。</td>
  </tr>
  <tr>
    <td>Acceleration of cluster snapshot restore speed **tw@qiancai** <!--1681--></td>
    <td>An optimization to involve all TiKV nodes in the preparation step for cluster restores was introduced to leverage scale such that restore speeds for a cluster are much faster for larger sets of data on larger clusters. Real world tests exhibit restore acceleration of ~300% in slower cases.</td>
  </tr>
  <tr>
    <td>增强在有大量表时缓存 schema 信息的稳定性**tw@hfxsd** <!--1691--></td>
    <td>对于使用 TiDB 作为多租户应用程序记录系统的 SaaS 公司，经常需要存储大量的表。在以前的版本中，尽管支持处理百万级或更大数量的表，但可能会影响用户体验。TiDB v8.0.0 通过以下增强功能改善了这一问题：
  <ul>
    <li>引入新的 <a href="https://docs.pingcap.com/zh/tidb/v8.0/system-variables#tidb_schema_cache_size-new-in-v800">schema 缓存系统</a>，为表元数据提供了懒加载的 LRU (Least Recently Used) 缓存，并更有效地管理 schema 版本变更。</li>
    <li>支持在 <code>auto analyze</code> 中配置<a href="https://docs.pingcap.com/zh/tidb/v8.0/system-variables#tidb_enable_auto_analyze_priority_queue-从-v800-版本开始引入">优先队列</a>，使流程更加流畅，并在大量表的情况下提高稳定性。</li>
  </ul>
    </td>
  </tr>
  <tr>
    <td rowspan="1">数据库管理与可观测性</td>
    <td>支持观测索引使用情况 **tw@Oreoxmt** <!--1400--></td>
    <td>TiDB v8.0.0 引入 <a href="https://docs.pingcap.com/zh/tidb/v8.0/information-schema-tidb-index-usage"><code>INFORMATION_SCHEMA.TIDB_INDEX_USAGE</code></a> 表和 <a href="https://docs.pingcap.com/zh/tidb/v8.0/sys-schema.md"><code>sys.schema_unused_index</code></a> 视图，以提供索引的使用统计信息。该功能有助于用户评估所有索引的重要性并优化索引设计。</td>
  </tr>
  <tr>
    <td rowspan="3">数据迁移</td>
    <td><a href="https://docs.pingcap.com/zh/tidb/v8.0/ticdc-bidirectional-replication">TiCDC 支持在双向复制 (Bidirectional replication, BDR) 模式下同步 DDL 语句 (GA) </a>**tw@hfxsd** <!--1682/1689--></td>
    <td>TiCDC 支持将集群指定为 <code>PRIMARY</code> BDR role，并且可以将 DDL 语句从该集群同步到下游集群。</td>
    </td>
  </tr>
  <tr>
    <td>TiCDC 支持 <a href="https://docs.pingcap.com/zh/tidb/v8.0/ticdc-simple-protocol">Simple 协议</a> **tw@lilin90** <!--1646--></td>
    <td>TiCDC 引入了对新的 Simple 协议的支持，该协议支持带内模式跟踪功能。</td>
  </tr>
  <tr>
    <td>TiCDC 支持 <a href="https://docs.pingcap.com/zh/tidb/v8.0/ticdc-debezium">Debezium 协议</a> **tw@lilin90** <!--1652--></td>
    <td>TiCDC 现在可以使用生成 Debezium 格式消息的协议向 Kafka sink 发布复制事件。</td>
  </tr>
</tbody>
</table>

## 功能详情

### 可扩展性

- PD 支持微服务模式 [#5766](https://github.com/tikv/pd/issues/5766) @[binshi-bing](https://github.com/binshi-bing) **tw@qiancai** <!--1553/1558-->

    从 v8.0.0 开始，PD 支持微服务模式。该模式可将 PD 的时间戳分配和集群调度功能拆分为以下微服务单独部署，从而实现 PD 的性能扩展，解决大规模集群下 PD 性能瓶颈问题。

    - TSO 微服务：为整个集群提供单调递增的时间戳分配。
    - Scheduling 微服务：为整个集群提供调度功能，包括但不限于负载均衡、热点处理、副本修复、副本放置等。

    每个微服务都以独立进程的方式部署。当设置某个微服务的副本数大于 1 时，该微服务会自动实现主备的容灾模式，以确保服务的高可用性和可靠性。

    目前 PD 微服务仅支持通过 TiDB Operator 进行部署。当 PD 出现明显的性能瓶颈且无法升配的情况下，建议考虑使用该模式。

    更多信息，请参考[用户文档](https://docs.pingcap.com/zh/tidb-in-kubernetes/dev/pd-microservices)。

* 增强 Titan 引擎的易用性 [#16245](https://github.com/tikv/tikv/issues/16245) @[Connor1996](https://github.com/Connor1996) **tw@qiancai** <!--1708-->

    - 默认启用 Titan Blob 文件和 RocksDB Block 文件的共享缓存（[`shared-blob-cache`](/tikv-configuration-file.md#shared-blob-cache-tidb-从-v800-版本开始引入) 默认为 `true`），无需再单独配置 [`blob-cache-size`](/tikv-configuration-file.md#blob-cache-size)。
    - 支持动态修改 [`min-blob-size`](/tikv-configuration-file.md#min-blob-size)、[`blob-file-compression`](/tikv-configuration-file.md#blob-file-compression)、[`discardable-ratio`](/tikv-configuration-file.md#min-blob-size)，以提升使用 Titan 引擎时的性能和灵活性。

    更多信息，请参考[用户文档](/storage-engine/titan-configuration.md)。
    
### 性能

* BR 快照恢复速度最高提升 10 倍 GA [#50701](https://github.com/pingcap/tidb/issues/50701) @[3pointer](https://github.com/3pointer) @[Leavrth](https://github.com/Leavrth) **tw@qiancai** <!--1681-->

    从 TiDB v8.0.0 起，快照恢复提速正式发布，并默认启用。通过采用粗粒度打散 Region 算法、批量创建库表、降低 SST 文件下载和 Ingest 操作之间的相互影响、加速表统计信息恢复等改进措施，在保持数据充分打散的前提下，快照恢复的速度最高提升约 10 倍。该功能充分利用了每个 TiKV 节点的所有资源，实现并行快速恢复。根据实际案例的测试结果，单个 TiKV 节点的数据恢复速度稳定在 1.2 GB/s，能够在 1 小时内完成对 100 TB 数据的恢复。
    
    这意味着即使在高负载环境下，BR 工具也能够充分利用每个 TiKV 节点的资源，显著减少数据库恢复时间，增强数据库的可用性和可靠性，减少因数据丢失或系统故障引起的停机时间和业务损失。
 
    更多信息，请参考[用户文档](/br/br-snapshot-guide.md#恢复快照备份数据)。
    
* 新增支持下推以下函数到 TiFlash [#50975](https://github.com/pingcap/tidb/issues/50975) [#50485](https://github.com/pingcap/tidb/issues/50485) @[yibin87](https://github.com/yibin87) @[windtalker](https://github.com/windtalker) **tw@Oreoxmt** <!--1662--><!--1664-->

    * `CAST(DECIMAL AS DOUBLE)`
    * `POWER()`

  更多信息，请参考[用户文档](/tiflash/tiflash-supported-pushdown-calculations.md)。

* TiDB 的并发 HashAgg 算法支持数据落盘（实验特性）[#35637](https://github.com/pingcap/tidb/issues/35637) @[xzhangxian1008](https://github.com/xzhangxian1008) **tw@qiancai** <!--1365-->

    在之前的 TiDB 版本中，HashAgg 算子的并发算法不支持数据落盘。当 SQL 语句的执行计划包含并发的 HashAgg 算子时，该 SQL 语句的所有数据都只能在内存中进行处理。这导致内存需要处理大量数据，当超过内存限制时，TiDB 只能选择非并发 HashAgg 算法，无法通过并发提升性能。

    在 v8.0.0 中，TiDB 的并发 HashAgg 算法支持数据落盘。在任意并发条件下，HashAgg 算子都可以根据内存使用情况自动触发数据落盘，从而兼顾性能和数据处理量。目前，该功能作为实验特性，引入变量 `tidb_enable_concurrent_hashagg_spill` 控制是否启用支持落盘的并发 HashAgg 算法。当该变量为 `ON` 时，代表启用。该变量将在功能正式发布时废弃。

    更多信息，请参考[用户文档](/system-variables.md#tidb_enable_concurrent_hashagg_spill-从-v800-版本开始引入)。

* 自动统计信息收集引入优先级队列 [#50132](https://github.com/pingcap/tidb/issues/50132) @[hi-rustin](https://github.com/hi-rustin) **tw@hfxsd** <!--1640-->

    维持优化器统计信息的时效性是稳定数据库性能的关键，绝大多数用户依赖 TiDB 提供的[自动统计信息收集](/statistics.md#自动更新)来保持统计信息的更新。自动统计信息收集轮询所有对象的统计信息状态，并把健康度不足的对象加入队列，逐个收集并更新。在之前的版本中，这些对象的收集顺序是随机的，可能导致更需要更新的对象等待时间过长，从而引发潜在的数据库性能回退。

    从 v8.0.0 开始，自动统计信息收集引入了优先级队列，根据多种条件动态地为对象分配优先级，确保更有收集价值的对象优先被处理，比如新创建的索引、发生分区变更的分区表等。同时，TiDB 也会优先处理那些健康度较低的表，将它们安排在队列的前端。这一改进优化了收集顺序的合理性，能减少一部分统计信息过旧引发的性能问题，进而提升了数据库稳定性。

    更多信息，请参考[用户文档](/system-variables.md#tidb_enable_auto_analyze_priority_queue-从-v800-版本开始引入)。

* 解除执行计划缓存的部分限制 [#49161](https://github.com/pingcap/tidb/pull/49161) @[mjonss](https://github.com/mjonss) @[qw4990](https://github.com/qw4990) **tw@hfxsd** <!--1622/1585-->

    TiDB 支持[执行计划缓存](/sql-prepared-plan-cache.md)，能够有效降低交易类业务系统的处理时延，是提升性能的重要手段。在 v8.0.0 中，TiDB 解除了执行计划缓存的几个限制，含有以下内容的执行计划均能够被缓存：

    - [分区表](/partitioned-table.md)
    - [生成列](/generated-columns.md)，包含依赖生成列的对象（比如[多值索引](/choose-index.md#多值索引与执行计划缓存)）

  该增强扩展了执行计划缓存的使用场景，提升了复杂场景下数据库的整体性能。

    更多信息，请参考[用户文档](/sql-prepared-plan-cache.md)。

* 优化器增强对多值索引的支持 [#47759](https://github.com/pingcap/tidb/issues/47759) [#46539](https://github.com/pingcap/tidb/issues/46539) @[Arenatlx](https://github.com/Arenatlx) @[time-and-fate](https://github.com/time-and-fate) **tw@hfxsd** <!--1405/1584-->

    TiDB 自 v6.6.0 开始引入[多值索引](/sql-statements/sql-statement-create-index.md#多值索引)，提升对 JSON 数据类型的检索性能。在 v8.0.0 中，优化器增强了对多值索引的支持能力，使其在复杂场景下能够正确识别和利用多值索引来优化查询。

    * 优化器能够收集多值索引的统计信息，并利用这些信息来估算查询。当一条 SQL 可能选择到数个多值索引时，优化器可以识别开销更小的索引。
    * 在查询条件中使用 `OR` 连接多个 `member of` 条件时，优化器能够为每个 DNF Item（`member of` 条件）匹配一个有效的 Index Partial Path 路径，并通过 Union 操作将这些路径集合起来，形成一个 `Index Merge`，以实现更高效的条件过滤和数据读取。

  更多信息，请参考[用户文档](/sql-statements/sql-statement-create-index.md#多值索引)。

* 支持设置低精度 TSO 的更新间隔 [#51081](https://github.com/pingcap/tidb/issues/51081) @[Tema](https://github.com/Tema) **tw@hfxsd** <!--1725-->

    TiDB 的[低精度 TSO 功能](/system-variables.md#tidb_low_resolution_tso)使用定期更新的 TSO 作为事务时间戳。在可以容忍读到旧数据的情况下，该功能通过牺牲一定的实时性，降低小的只读事务获取 TSO 的开销，从而提升高并发读的能力。

    在 v8.0.0 之前，低精度 TSO 功能的 TSO 更新周期固定，无法根据实际业务需要进行调整。在 v8.0.0 中，TiDB 引入变量 `tidb_low_resolution_tso_update_interval` 来控制低精度 TSO 功能更新 TSO 的周期。该功能仅在低精度 TSO 功能启用时有效。
    
    更多信息，请参考[用户文档](/system-variables.md#tidb_low_resolution_tso_update_interval-从-v800-版本开始引入)。

### 稳定性

* 支持根据 LRU 算法缓存所需的 schema 信息，以减少 TiDB server 的内存消耗（实验特性）[#50959](https://github.com/pingcap/tidb/issues/50959) @[gmhdbjd](https://github.com/gmhdbjd) **tw@hfxsd** <!--1691-->

    在 v8.0.0 之前，每个 TiDB 节点都会缓存所有表的 schema 信息。在表数量较多的情况下，例如高达几十万张表，仅缓存这些表的 schema 信息就会占用大量内存。
    
    从 v8.0.0 开始，TiDB 引入 [`tidb_schema_cache_size`](/system-variables.md#tidb_schema_cache_size-从-v800-版本开始引入) 系统变量，允许设置缓存 schema 信息所能使用的内存上限，从而避免占用过多的内存。开启该功能后，TiDB 将使用 Least Recently Used (LRU) 算法缓存所需的表，有效降低 schema 信息占用的内存。

    更多信息，请参考[用户文档](/system-variables.md#tidb_schema_cache_size-从-v800-版本开始引入)。
    
### 高可用

* 代理组件 TiProxy 成为正式功能 (GA) [#413](https://github.com/pingcap/tiproxy/issues/413) @[djshow832](https://github.com/djshow832) @[xhebox](https://github.com/xhebox) **tw@Oreoxmt** <!--1698-->

    TiDB v7.6.0 引入了代理组件 TiProxy 作为实验特性。TiProxy 是 TiDB 的官方代理组件，位于客户端和 TiDB server 之间，为 TiDB 提供负载均衡、连接保持功能，让 TiDB 集群的负载更加均衡，并在维护操作期间不影响用户对数据库的连接访问。
    
    在 v8.0.0 中，TiProxy 成为正式功能，完善了签名证书自动生成、监控等功能。
    
    TiProxy 的应用场景如下：

    * 在 TiDB 集群进行滚动重启、滚动升级、缩容等维护操作时，TiDB server 会发生变动，导致客户端与发生变化的 TiDB server 的连接中断。通过使用 TiProxy，可以在这些维护操作过程中平滑地将连接迁移至其他 TiDB server，从而让客户端不受影响。
    * 所有客户端对 TiDB server 的连接都无法动态迁移至其他 TiDB server。当多个 TiDB server 的负载不均衡时，可能出现整体集群资源充足，但某些 TiDB server 资源耗尽导致延迟大幅度增加的情况。为解决此问题，TiProxy 提供连接动态迁移功能，在客户端无感的前提下，将连接从一个 TiDB server 迁移至其他 TiDB server，从而实现 TiDB 集群的负载均衡。

  TiProxy 已集成至 TiUP、TiDB Operator、TiDB Dashboard 等 TiDB 基本组件中，可以方便地进行配置、部署和运维。

    更多信息，请参考[用户文档](/tiproxy/tiproxy-overview.md)。

### SQL 功能

* 支持处理大量数据的 DML 类型（实验特性）[#50215](https://github.com/pingcap/tidb/issues/50215) @[ekexium](https://github.com/ekexium) **tw@Oreoxmt** <!--1694-->

    在 TiDB v8.0.0 之前，所有事务数据在提交之前均存储在内存中。当处理大量数据时，事务所需的内存成为限制 TiDB 处理事务大小的瓶颈。虽然 TiDB 非事务 DML 功能通过拆分 SQL 语句的方式尝试解决事务大小限制，但该功能存在多种限制，在实际应用中的体验并不理想。

    从 v8.0.0 开始，TiDB 支持处理大量数据的 DML 类型。该 DML 类型在执行过程中将数据及时写入 TiKV，避免将所有事务数据持续存储在内存中，从而支持处理超过内存限制的大量数据。这种 DML 类型在保证事务完整性的同时，采用与标准 DML 相同的语法。`INSERT`、`UPDATE`、`REPLACE` 和 `DELETE` 语句均可使用这种新的 DML 类型来执行大数据量的 DML 操作。

    支持处理大量数据的 DML 类型依赖于 [Pipelined DML](https://github.com/pingcap/tidb/blob/master/docs/design/2024-01-09-pipelined-DML.md) 特性，仅支持在自动提交的事务中使用。你可以通过 [`tidb_dml_type`](/system-variables.md#tidb_dml_type-从-v800-版本开始引入) 系统变量控制是否启用该 DML 类型。

    更多信息，请参考[用户文档](/system-variables.md#tidb_dml_type-从-v800-版本开始引入)。

* 支持在 TiDB 建表时使用更多的表达式设置列的默认值（实验特性）[#50936](https://github.com/pingcap/tidb/issues/50936) @[zimulala](https://github.com/zimulala) **tw@hfxsd** <!--1690-->

    在 v8.0.0 之前，建表时指定列的默认值仅限于固定的字符串、数字和日期。从 v8.0.0 开始，TiDB 支持使用部分表达式作为列的默认值，例如将列的默认值设置为 `UUID()`，从而满足多样化的业务需求。

    更多信息，请参考[用户文档](/data-type-default-values.md#表达式默认值)。

* 支持系统变量 `div_precision_increment` [#51501](https://github.com/pingcap/tidb/issues/51501) @[yibin87](https://github.com/yibin87) **tw@hfxsd** <!--1566-->

    MySQL 8.0 增加了变量 `div_precision_increment`，用于指定除法 `/` 运算结果增加的小数位数。在 v8.0.0 之前，TiDB 不支持该变量，而是按照 4 位小数进行除法计算。从 v8.0.0 开始，TiDB 支持该变量，你可以根据需要指定除法运算结果增加的小数位数。

    更多信息，请参考[用户文档](/system-variables.md#div_precision_increment-从-v800-版本开始引入)。

### 数据库管理

* PITR 支持 Amazon S3 对象锁定 [#51184](https://github.com/pingcap/tidb/issues/51184) @[RidRisR](https://github.com/RidRisR) **tw@lilin90** <!--1604-->

    Amazon S3 对象锁定功能支持用户通过设置留存期，有效防止备份数据在指定时间内被意外或故意删除，提升了数据的安全性和完整性。从 v6.3.0 起，BR 为快照备份引入了对 Amazon S3 对象锁定功能的支持，为全量备份增加了额外的安全性保障。从 v8.0.0 起，PITR 也引入了对 Amazon S3 对象锁定功能的支持，无论是全量备份还是日志数据备份，都可以通过对象锁定功能提供更可靠的数据保护，进一步加强了数据备份和恢复的安全性，并满足了监管方面的需求。
    
    更多信息，请参考[用户文档](/br/backup-and-restore-storages.md#存储服务其他功能支持)。
    
* 支持在会话级将不可见索引 (Invisible Indexes) 调整为可见 [#50653](https://github.com/pingcap/tidb/issues/50653) @[hawkingrei](https://github.com/hawkingrei) **tw@Oreoxmt** <!--1401-->

    在优化器选择索引以优化查询执行时，默认情况下不会选择[不可见索引](/sql-statements/sql-statement-create-index.md#不可见索引)。这一机制通常用于在评估是否删除某个索引之前。如果担心删除索引可能导致性能下降，可以先将索引设置为不可见，以便在必要时快速将其恢复为可见。
    
    从 v8.0.0 开始，你可以将会话级系统变量 [`tidb_opt_use_invisible_indexes`](/system-variables.md#) 设置为 `ON`，让当前会话识别并使用不可见索引。利用这个功能，在添加新索引并希望测试其效果时，可以先将索引创建为不可见索引，然后通过修改该系统变量在当前会话中进行测试新索引的性能，而不影响其他会话。这一改进提高了进行性能调优的安全性，并有助于增强生产数据库的稳定性。

    更多信息，请参考[用户文档](/sql-statements/sql-statement-create-index.md#不可见索引)。

* 支持将 general log 写入独立文件 [#51248](https://github.com/pingcap/tidb/issues/51248) @[Defined2014](https://github.com/Defined2014) **tw@hfxsd** <!--1632-->

    general log 是与 MySQL 兼容的功能，开启后能够记录数据库执行的所有 SQL 语句，为问题诊断提供依据。TiDB 也支持此功能，你可以通过设置变量 [`tidb_general_log`](/system-variables.md#tidb_general_log) 开启该功能。在之前的版本中，general log 的内容只能和其他信息一起写入实例日志中，这对于需要长期保存日志的用户来说并不方便。

    从 v8.0.0 开始，你可以通过配置项 [`log.general-log-file`](/tidb-configuration-file.md#general-log-file-从-v800-版本开始引入) 指定一个文件名，将 general log 单独写入该文件。和实例日志一样，general log 也遵循日志的轮询和保存策略。
   
    另外，为了减少历史日志文件所占用的磁盘空间，TiDB 在 v8.0.0 支持了原生的日志压缩选项。你可以将配置项 [`log.file.compression`](/tidb-configuration-file.md#compression-从-v800-版本开始引入) 设置为 `gzip`，使得轮询出的历史日志自动以 [`gzip`](https://www.gzip.org/) 格式压缩。

    更多信息，请参考[用户文档](/tidb-configuration-file.md#general-log-file-从-v800-版本开始引入)。
        
### 可观测性

* 支持观测索引使用情况 [#49830](https://github.com/pingcap/tidb/issues/49830) @[YangKeao](https://github.com/YangKeao) **tw@Oreoxmt** <!--1400-->

    正确的索引设计是提升数据库性能的重要前提。TiDB v8.0.0 新增内存表 [`INFORMATION_SCHEMA.TIDB_INDEX_USAGE`](/information-schema/information-schema-tidb-index-usage.md)，用于记录当前 TiDB 节点中所有索引的访问统计信息，包括：

    * 扫描该索引的语句的累计执行次数
    * 访问该索引时扫描的总行数
    * 扫描索引时的选择率分布
    * 最近一次访问该索引的时间

  通过这些信息，你可以识别未被优化器使用的索引以及过滤效果不佳的索引，从而优化索引设计，提升数据库性能。

    此外，TiDB v8.0.0 新增与 MySQL 兼容的视图 [`sys.schema_unused_index`](/sys-schema.md)，用于记录自 TiDB 上次启动以来未被使用的索引信息。对于从 v8.0.0 之前版本升级的集群，`sys` 中的内容不会自动创建。你可以参考 [`sys`](/sys-schema.md) 手动创建。

    更多信息，请参考[用户文档](/information-schema/information-schema-tidb-index-usage.md)。

### 安全

* TiKV 静态加密支持 Google [Key Management Service (Cloud KMS)](https://cloud.google.com/docs/security/key-management-deep-dive?hl=zh-cn) [#8906](https://github.com/tikv/tikv/issues/8906) @[glorv](https://github.com/glorv) **tw@qiancai** <!--1612-->

    TiKV 通过静态加密功能对存储的数据进行加密，以确保数据的安全性。静态加密的安全核心点在于密钥管理。从 v8.0.0 起，你可以通过 Google Cloud KMS 管理 TiKV 的主密钥，构建基于 Cloud KMS 的静态加密能力，从而提高用户数据的安全性。
    
    要启用基于 Google Cloud KMS 的静态加密，你需要在 Google Cloud 上创建一个密钥，然后在 TiKV 配置文件中添加 `[security.encryption.master-key]` 部分的配置。

    更多信息，请参考[用户文档](/encryption-at-rest.md#tikv-静态加密)。

* TiDB 日志脱敏增强 [#51306](https://github.com/pingcap/tidb/issues/51306) @[xhebox](https://github.com/xhebox) **tw@hfxsd** <!--1229-->

    TiDB 日志脱敏增强是基于对日志文件中 SQL 文本信息的数据进行标记，以便支持用户在查看时进行敏感数据的安全展示。用户可以更灵活自主地在展示环节控制是否对日志信息进行脱敏，以支持 TiDB 日志在不同场景下的安全使用，提升了客户使用日志脱敏能力的安全性和灵活性。要使用此功能请通过修改系统变量 `tidb_redact_log` 的值设置为 `marker`，此时 TiDB 的运行日志将对 SQL 文本进行标记，查看时将基于标记进行数据的安全展示，从而实现日志信息的保护。

    更多信息，请参考[用户文档](链接)。

### 数据迁移
* TiCDC 支持 Simple 协议 [#9898](https://github.com/pingcap/tiflow/issues/9898) @[3AceShowHand](https://github.com/3AceShowHand) **tw@lilin90** <!--1646-->

    TiCDC 引入了对新的 Simple 协议的支持，该协议支持带内模式跟踪 (in-band schema tracking)。

    更多信息，请参考[用户文档](/ticdc/ticdc-simple-protocol.md)。

* TiCDC 支持 Debezium 协议 [#1799](https://github.com/pingcap/tiflow/issues/1799) @[breezewish](https://github.com/breezewish) **tw@lilin90** <!--1652-->

    TiCDC 现在可以使用一种生成 Debezium 格式的事件消息的协议，将复制事件发布到 Kafka sink。这有助于简化那些当前使用 Debezium 从 MySQL 拉取数据进行下游处理的用户从 MySQL 迁移到 TiDB 的过程。

    更多信息，请参考[用户文档](/ticdc/ticdc-debezium.md)。
* TiCDC 支持通过双向复制模式 (Bi-Directional Replication, BDR) 同步 DDL 语句 (GA) [#10301](https://github.com/pingcap/tiflow/issues/10301) [#48519](https://github.com/pingcap/tidb/issues/48519) @[okJiang](https://github.com/okJiang) @[asddongmen](https://github.com/asddongmen) **tw@hfxsd** <!--1689/1682-->

    TiDB v7.6.0 引入了通过双向复制模式同步 DDL 语句的功能作为实验特性。以前，TiCDC 不支持复制 DDL 语句，因此要使用 TiCDC 双向复制必须将 DDL 语句分别应用到两个 TiDB 集群。有了该特性，TiCDC 可以为一个集群分配 `PRIMARY` BDR role，并将该集群的 DDL 语句复制到下游集群。该功能在 v8.0.0 成为正式功能。

    更多信息，请参考[用户文档](/ticdc/ticdc-bidirectional-replication.md)。

* DM 支持使用用户提供的密钥对源数据库和目标数据库的密码进行加密和解密 [#9492](https://github.com/pingcap/tiflow/issues/9492) @[D3Hunter](https://github.com/D3Hunter) **tw@qiancai** <!--1497-->

    在之前的版本中，DM 使用了一个内置的一个固定秘钥，安全性相对较低。从 v8.0.0 开始，你可以上传并指定一个密钥文件，用于对上下游数据库的密码进行加密和解密操作。此外，你还可以按需替换秘钥文件，以提升数据的安全性。

    更多信息，请参考[用户文档](dm/dm-customized-secret-key.md)。

* 支持 `IMPORT INTO ... FROM SELECT` 语法，增强 `IMPORT INTO` 功能（实验特性） [#49883](https://github.com/pingcap/tidb/issues/49883) @[D3Hunter](https://github.com/D3Hunter) **tw@qiancai** <!--1680-->

    在之前的 TiDB 版本中，将查询结果导入目标表只能通过 `INSERT INTO ... SELECT` 语句，但该语句在一些大数据量的场景中的导入效率较低。从 v8.0.0 开始，TiDB 新增支持通过 `IMPORT INTO ... FROM SELECT` 将 `SELECT` 的查询结果导入到一张空的 TiDB 目标表中，其性能最高可达 `INSERT INTO ... SELECT` 的 8 倍，可以大幅缩短导入所需的时间。
    
    此外，你还可以通过 `IMPORT INTO ... FROM SELECT` 导入使用 [`AS OF TIMESTAMP`](/as-of-timestamp.md) 查询的历史数据。

    更多信息，请参考[用户文档](sql-statements/sql-statement-import-into.md)。        
    
* TiDB Lightning 简化冲突处理策略，同时支持以 "replace" 方式处理冲突数据（实验特性） [#51036](https://github.com/pingcap/tidb/issues/51036) @[lyzx2001](https://github.com/lyzx2001) **tw@qiancai** <!--1684-->

    在之前的版本中，TiDB Lightning 逻辑导入模式有一套[数据冲突处理策略](/tidb-lightning/tidb-lightning-logical-import-mode-usage.md)，物理导入模式时有[两套数据冲突处理策略](/tidb-lightning/tidb-lightning-physical-import-mode-usage.md#冲突数据检测)，不易理解和配置。
    
    从 v8.0.0 开始，TiDB Lightning 废弃了物理导入模式下的[旧版冲突检测](/tidb-lightning/tidb-lightning-physical-import-mode-usage.md#旧版冲突检测从-v800-开始已被废弃)策略，支持通过 [`conflict.strategy`](tidb-lightning/tidb-lightning-configuration.md) 参数统一控制逻辑导入和物理导入模式的冲突检测策略，并简化了该参数的配置。此外，在物理导入模式下，当导入遇到主键或唯一键冲突的数据时，`replace` 策略支持保留最新的数据、覆盖旧的数据。

    更多信息，请参考[用户文档](tidb-lightning/tidb-lightning-configuration.md)。    
    
* 全局排序成为正式功能 (GA)，可显著提升 `IMPORT INTO` 任务的导入性能和稳定性，支持 40 TiB 的数据导入 [#45719](https://github.com/pingcap/tidb/issues/45719) @[lance6716](https://github.com/lance6716) **tw@qiancai** <!--1580-->

    在 v7.4.0 以前，当使用[分布式执行框架](/tidb-distributed-execution-framework.md) 执行 `IMPORT INTO` 任务时，由于本地存储空间有限，TiDB 只能对部分数据进行局部排序后再导入到 TiKV。这导致了导入到 TiKV 的数据存在较多的重叠，需要 TiKV 在导入过程中执行额外的 compaction 操作，影响了 TiKV 的性能和稳定性。

    随着 v7.4.0 引入全局排序实验特性，TiDB 支持将需要导入的数据暂时存储在外部存储（如 Amazon S3）中进行全局排序后再导入到 TiKV 中，使 TiKV 无需在导入过程中执行 compaction 操作。全局排序在 v8.0.0 成为正式功能 (GA)，可以降低 TiKV 对资源的额外消耗，显著提升 `IMPORT INTO` 的性能和稳定性。

    更多信息，请参考[用户文档](/tidb-global-sort.md)。    
    
* 功能标题 [#issue号](链接) @[贡献者 GitHub ID](链接) **tw@xxx** <!--1234-->

    功能描述（需要包含这个功能是什么、在什么场景下对用户有什么价值、怎么用）

    更多信息，请参考[用户文档](链接)。

## 兼容性变更

> **注意：**
>
> 以下为从 v7.6.0 升级至当前版本 (v8.0.0) 所需兼容性变更信息。如果从 v7.5.0 或之前版本升级到当前版本，可能也需要考虑和查看中间版本 Release Notes 中提到的兼容性变更信息。

### 行为变更

* 在之前版本中，启用添加索引加速功能 (`tidb_ddl_enable_fast_reorg = ON`) 后，编码后的索引键值 ingest 到 TiKV 的过程使用了并发数 (`16`)，并未根据下游 TiKV 的处理能力进行动态调整。从 v8.0.0 开始，支持使用 [`tidb_ddl_reorg_worker_cnt`](/system-variables.md#tidb_ddl_reorg_worker_cnt-从-v800-版本开始引入) 并发数，该变量默认值为 `4`，相比之前的默认值 `16`，在 ingest 索引键值对时性能可能会有所下降。你可以根据集群的负载按需调整该参数。**tw@hfxsd** <!--无 FD-->

### MySQL 兼容性

* `KEY` 分区类型支持分区字段列表为空的语句，具体行为和 MySQL 保持一致。**tw@hfxsd** <!--无 FD-->

### 系统变量

| 变量名  | 修改类型（包括新增/修改/删除/更名）    | 描述 |
|--------|------------------------------|------|
| [`tidb_disable_txn_auto_retry`](/system-variables.md#tidb_disable_txn_auto_retry)  | 废弃 | 从 v8.0.0 开始，该系统变量被废弃，TiDB 不再支持乐观事务的自动重试。推荐使用[悲观事务模式](/pessimistic-transaction.md)。如果使用乐观事务模式发生冲突，请在应用里捕获错误并重试。 |
| `tidb_ddl_version` | 更名 | 用于控制是否开启 TiDB DDL V2。为了使变量名称更直观，从 v8.0.0 起，该参数更名为 [`tidb_enable_fast_create_table`](/system-variables.md#tidb_enable_fast_create_table-从-v800-版本开始引入) 。 |
| [`tidb_enable_collect_execution_info`](/system-variables.md#tidb_enable_collect_execution_info) | 修改 | 增加控制是否维护[访问索引有关的统计信息](/information-schema/information-schema-tidb-index-usage.md)，默认值为 `ON`。 |
| [`tidb_redact_log`](/system-variables.md#tidb_redact_log) | 修改 | 控制在记录 TiDB 日志和慢日志时如何处理 SAL 文本中的用户信息，可选值为 `OFF`、`ON`，以分别支持明文日志信息、屏蔽日志信息。为了提供更丰富的处理日志中用户信息的方式，v8.0.0 中增加了 `MARKER` 选项，支持标记日志信息。当变量值为 `MARKER` 时，日志中的用户信息将被标记处理，可以在之后决定是否对日志信息进行脱敏。 |
| [`div_precision_increment`](/system-variables.md#div_precision_increment-从-v800-版本开始引入) | 新增 | 用于指定使用运算符 `/` 执行除法操作时，结果增加的小数位数。该功能与 MySQL 保持一致。 |
| [`tidb_dml_type`](/system-variables.md#tidb_dml_type-从-v800-版本开始引入) | 新增 | 设置 DML 语句的执行方式，可选值为 `"standard"` 和 `"bulk"`。 |
| [`tidb_enable_auto_analyze_priority_queue`](/system-variables.md#tidb_enable_auto_analyze_priority_queue-从-v800-版本开始引入) | 新增 | 控制是否启用优先队列来调度自动收集统计信息的任务。开启该变量后，TiDB 会优先收集那些最需要收集统计信息的表的统计信息。 |
| [`tidb_enable_concurrent_hashagg_spill`](/system-variables.md#tidb_enable_concurrent_hashagg_spill-从-v800-版本开始引入) | 新增 | 控制 TiDB 是否支持并发 HashAgg 进行落盘。当该变量设置为 `ON` 时，并发 HashAgg 将支持落盘。该变量将在功能正式发布时废弃。 |
| [`tidb_enable_fast_create_table`](/system-variables.md#tidb_enable_fast_create_table-从-v800-版本开始引入) | 新增 | 用于控制是否开启 [TiDB 加速建表](/fast-create-table.md)。将该变量的值设置为 `ON` 可以开启该功能，设置为 `OFF` 关闭该功能。默认值为 `OFF`。开启后，将使用 TiDB 加速建表执行 DDL 语句。 |
| [`tidb_load_binding_timeout`](/system-variables.md#tidb_load_binding_timeout-从-v800-版本开始引入) | 新增 | 控制加载 binding 的超时时间。当加载 binding 的执行时间超过该值时，会停止加载。 |
| [`tidb_low_resolution_tso_update_interval`](/system-variables.md#tidb_low_resolution_tso_update_interval-从-v800-版本开始引入) | 新增 | 设置更新 TiDB [缓存 timestamp](/system-variables.md#tidb_low_resolution_tso) 的更新时间间隔。 |
| [`tidb_opt_use_invisible_indexes`](/system-variables.md#tidb_opt_use_invisible_indexes-从-v800-版本开始引入) | 新增 | 控制会话中是否允许优化器选择[不可见索引](/sql-statements/sql-statement-create-index.md#不可见索引)。当修改变量为 `ON` 时，对该会话中的查询，优化器可以选择不可见索引进行查询优化。|
| [`tidb_schema_cache_size`](/system-variables.md#tidb_schema_cache_size-从-v800-版本开始引入)  |  新增 |  设置缓存 schema 信息可以使用的内存上限，避免占用过多的内存。开启该功能后，将使用 LRU 算法来缓存所需的表，有效减小 schema 信息占用的内存。    |

### 配置文件参数

| 配置文件 | 配置项 | 修改类型 | 描述 |
| -------- | -------- | -------- | -------- |
| TiDB | [`instance.tidb_enable_collect_execution_info`](/tidb-configuration-file.md#tidb_enable_collect_execution_info) | 修改 | 增加控制是否维护[访问索引有关的统计信息](/information-schema/information-schema-tidb-index-usage.md)，默认值为 `true`。 |
| TiDB | [`tls-version`](/tidb-configuration-file.md#tls-version) | 修改 | 该参数不再支持 `"TLSv1.0"` 和 `"TLSv1.1"`，只支持 `"TLSv1.2"` 和 `"TLSv1.3"`。   |
| TiDB | [`log.file.compression`](/tidb-configuration-file.md#compression-从-v800-版本开始引入) | 新增 | 指定轮询日志的压缩格式。默认为空，即不压缩轮询日志。 |
| TiDB | [`log.general-log-file`](/tidb-configuration-file.md#general-log-file-从-v800-版本开始引入) | 新增 | 指定 general log 的保存文件。默认为空，general log 将会写入实例文件。 |
| TiDB | [`tikv-client.enable-replica-selector-v2`](/tidb-configuration-file.md#enable-replica-selector-v2-从-v800-版本开始引入) | 新增 | 控制是否使用 replica selector v2 版本，默认值为 `true`。 |
| TiKV | [`log-backup.initial-scan-rate-limit`](/system-variables.md#initial-scan-rate-limit-从-v620-版本开始引入) | 修改 | 增加了最小值为 `1MiB` 的限制。 |
| TiKV | [`raftstore.store-io-pool-size`](/tikv-configuration-file.md#store-io-pool-size-从-v530-版本开始引入) | 修改 | 为了提升 TiKV 性能，该参数默认值从 `0` 修改为 `1`，表示 StoreWriter 线程池的大小默认为 `1`。|
| TiKV | [`security.encryption.master-key.vendor`] | 新增 | 指定住密钥的服务商类型，支持可选值为 `gcp`、`azure` |
| TiDB Lightning  | [`tikv-importer.duplicate-resolution`](/tidb-lightning/tidb-lightning-physical-import-mode-usage.md#旧版冲突检测从-v800-开始已被废弃)  | 废弃 | 用于在物理导入模式下设置是否检测和解决唯一键冲突的记录。从 v8.0.0 开始使用新参数 [`conflict.strategy`](/tidb-lightning/tidb-lightning-configuration.md#tidb-lightning-任务配置) 替代。 |
| TiDB Lightning  | [`conflict.precheck-conflict-before-import`](/tidb-lightning/tidb-lightning-configuration.md#tidb-lightning-任务配置)  | 新增 | 控制是否开启前置冲突检测，即导入数据到 TiDB 前，先检查所需导入的数据是否存在冲突。该参数默认值为 `false`，表示仅开启后置冲突检测。仅当导入模式为物理导入模式 (`tikv-importer.backend = "local"`) 时可以使用该配置项。 |
| TiDB Lightning  | `logical-import-batch-rows` | 新增 | 用于在逻辑导入模式下设置一个 batch 里提交的数据行数，默认值为 `65536`。 |
| TiDB Lightning  | `logical-import-batch-size` | 新增 | 用于在逻辑导入模式下设置一个 batch 里提交的数据大小，取值为字符串类型，默认值为 `"96KiB"`，单位可以为 KB、KiB、MB、MiB 等存储单位。 |
| Data Migration  | [`secret-key-path`](/dm/dm-master-configuration-file.md) | 新增 | 用于指定加解密上下游密码的密钥文件所在的路径。该文件内容必须是长度为 64 个字符的十六进制的 AES-256 密钥。 |
| TiCDC | [`tls-certificate-file`](ticdc/ticdc-sink-to-pulsar.md) | 新增 | 用于指定 Pulsar 启用 TLS 加密传输时，客户端的加密证书文件路径。 |
| TiCDC | [`tls-key-file-path`](ticdc/ticdc-sink-to-pulsar.md) | 新增 | 用于指定 Pulsar 启用 TLS 加密传输时，客户端的加密私钥路径。 |


### 系统表

* 新增系统表 [`INFORMATION_SCHEMA.TIDB_INDEX_USAGE`](/information-schema/information-schema-tidb-index-usage.md) 和 [`INFORMATION_SCHEMA.CLUSTER_TIDB_INDEX_USAGE`](/information-schema/information-schema-tidb-index-usage.md#cluster_tidb_index_usage) 用于记录 TiDB 节点中索引的访问统计信息。**tw@Oreoxmt**
* 新增系统数据库 [`sys`](/sys-schema.md) 和 [`sys.schema_unused_index`](/sys-schema.md#schema_unused_index) 视图，用于记录自 TiDB 上次启动以来未被使用的索引信息。**tw@Oreoxmt** 

## 离线包变更

## 废弃功能

* 从 v8.0.0 开始，[`tidb_disable_txn_auto_retry`](/system-variables.md#tidb_disable_txn_auto_retry) 变量被废弃。废弃后，TiDB 不再支持乐观事务的自动重试。作为替代，当使用乐观事务模式发生冲突时，请在应用里捕获错误并重试，或改用[悲观事务模式](/pessimistic-transaction.md)。**tw@lilin90** <!--1671-->
* 从 v8.0.0 开始，TiDB 不再支持 TLSv1.0 和 TLSv1.1 协议。请升级 TLS 至 TLSv1.2 或 TLSv1.3。
* [执行计划绑定的自动演进](/sql-plan-management.md#自动演进绑定-baseline-evolution) 计划在后续版本被重新设计，相关的变量和行为会发生变化。

## 改进提升

+ TiDB

    - 提升 Sort 算子的数据落盘性能 [#47733](https://github.com/pingcap/tidb/issues/47733) @[xzhangxian1008](https://github.com/xzhangxian1008) **tw@Oreoxmt** <!--1609-->
    - 优化数据落盘功能的退出机制，支持在数据落盘过程中取消查询 [#50511](https://github.com/pingcap/tidb/issues/50511) @[wshwsh12](https://github.com/wshwsh12) **tw@qiancai** <!--1635-->
    - 用多个等值条件做表连接时，支持利用匹配到部分条件的索引做 Index Join [#47233](https://github.com/pingcap/tidb/issues/47233) @[winoros](https://github.com/winoros) **tw@Oreoxmt** <!--1601-->
    - Index Join 允许被连接的一侧为聚合数据集 [#37068](https://github.com/pingcap/tidb/issues/37068) @[elsa0520](https://github.com/elsa0520) **tw@Oreoxmt** <!--1510-->
    - 支持同时提交 16 个 `IMPORT INTO ... FROM FILE` 任务，方便批量导入数据到目标表，极大地提升了数据文件导入的效率和性能 [#49008](https://github.com/pingcap/tidb/issues/49008) @[D3Hunter](https://github.com/D3Hunter) **tw@qiancai** <!--1680-->
    - (dup): release-7.1.4.md > 改进提升> TiDB - 当设置 `force-init-stats` 为 `true` 时，即 TiDB 启动时等待统计信息初始化完成后再对外提供服务，这一设置不再影响 HTTP server 提供服务，用户仍可查看监控 [#50854](https://github.com/pingcap/tidb/issues/50854) @[hawkingrei](https://github.com/hawkingrei)

+ TiKV

    - 强化 TSO 校验检测，提升配置或操作不当时集群 TSO 的鲁棒性 [#16545](https://github.com/tikv/tikv/issues/16545) @[cfzjywxk](https://github.com/cfzjywxk) **tw@qiancai** <!--1624-->
    - 优化清理悲观锁逻辑，提升未提交事务处理性能 [#16158](https://github.com/tikv/tikv/issues/16158) @[cfzjywxk](https://github.com/cfzjywxk) **tw@Oreoxmt** <!--1661-->
    - 增加 TiKV 统一健康控制，降低单个 TiKV 节点异常对集群访问性能的影响。可通过 [`tikv-client.enable-replica-selector-v2`](/tidb-configuration-file.md#enable-replica-selector-v2-从-v800-版本开始引入) 禁用该优化 [#16297](https://github.com/tikv/tikv/issues/16297) [#1104](https://github.com/tikv/client-go/issues/1104) [#1167](https://github.com/tikv/client-go/issues/1167) @[MyonKeminta](https://github.com/MyonKeminta) @[zyguan](https://github.com/zyguan) @[crazycs520](https://github.com/crazycs520) **tw@qiancai** <!--1707-->

+ PD

    - note [#issue](链接) @[贡献者 GitHub ID](链接)
    - note [#issue](链接) @[贡献者 GitHub ID](链接)

+ TiFlash

    - note [#issue](链接) @[贡献者 GitHub ID](链接)
    - note [#issue](链接) @[贡献者 GitHub ID](链接)
    - (dup): release-7.6.0.md > 改进提升> TiFlash - 支持在存算分离架构下通过合并相同数据的读取操作，提升多并发下的数据扫描性能 [#6834](https://github.com/pingcap/tiflash/issues/6834) @[JinheLin](https://github.com/JinheLin)

+ Tools

    + Backup & Restore (BR)

        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - (dup): release-7.5.1.md > 改进提升> Tools> Backup & Restore (BR) - 使用更优的算法，提升数据恢复过程中 SST 文件合并的速度 [#50613](https://github.com/pingcap/tidb/issues/50613) @[Leavrth](https://github.com/Leavrth)
        - (dup): release-7.5.1.md > 改进提升> Tools> Backup & Restore (BR) - 支持在数据恢复过程中批量创建数据库 [#50767](https://github.com/pingcap/tidb/issues/50767) @[Leavrth](https://github.com/Leavrth)
        - (dup): release-7.5.1.md > 改进提升> Tools> Backup & Restore (BR) - 在日志备份过程中，增加了在日志和监控指标中打印影响 global checkpoint 推进的最慢的 Region 的信息 [#51046](https://github.com/pingcap/tidb/issues/51046) @[YuJuncen](https://github.com/YuJuncen)
        - (dup): release-7.5.1.md > 改进提升> Tools> Backup & Restore (BR) - 提升了 `RESTORE` 语句在大数据量表场景下的建表性能 [#48301](https://github.com/pingcap/tidb/issues/48301) @[Leavrth](https://github.com/Leavrth)

    + TiCDC

        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - (dup): release-7.5.1.md > 改进提升> Tools> TiCDC - 支持[查询 changefeed 的下游同步状态](https://docs.pingcap.com/zh/tidb/v7.5/ticdc-open-api-v2#查询特定同步任务是否完成)，以确认 TiCDC 是否已将所接收到的上游变更完全同步到下游 [#10289](https://github.com/pingcap/tiflow/issues/10289) @[hongyunyan](https://github.com/hongyunyan)

    + TiDB Data Migration (DM)

        - 在 MariaDB 主从复制的场景中，即 MariaDB 主实例 -> MariaDB 从实例 -> DM -> TiDB 的迁移场景，当 `gtid_strict_mode = off` 且 MariaDB 从实例的 GTID 不严格递增时（例如，有业务数据写入 MariaDB 从实例），此时 DM 任务会报错 `less than global checkpoint position`。从 v8.0.0 开始，TiDB 兼容该场景，数据可以正常迁移到下游。[#10741](https://github.com/pingcap/tiflow/issues/10741) @[okJiang](https://github.com/okJiang) **tw@hfxsd** <!--1683-->

    + TiDB Lightning

        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - note [#issue](链接) @[贡献者 GitHub ID](链接)

    + TiUP

        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - note [#issue](链接) @[贡献者 GitHub ID](链接)

## 错误修复

+ TiDB

    - note [#issue](链接) @[贡献者 GitHub ID](链接)
    - note [#issue](链接) @[贡献者 GitHub ID](链接)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复查询使用 `NATURAL JOIN` 时可能报错 `Column ... in from clause is ambiguous` 的问题 [#32044](https://github.com/pingcap/tidb/issues/32044) @[AilinKid](https://github.com/AilinKid)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复 TiDB 错误地消除 `group by` 中的常量值导致查询结果出错的问题 [#38756](https://github.com/pingcap/tidb/issues/38756) @[hi-rustin](https://github.com/hi-rustin)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复 `LEADING` hint 在 `UNION ALL` 语句中无法生效的问题 [#50067](https://github.com/pingcap/tidb/issues/50067) @[hawkingrei](https://github.com/hawkingrei)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复 `BIT` 类型的列在参与一些函数计算时，可能会因为 decode 失败导致查询出错的问题 [#49566](https://github.com/pingcap/tidb/issues/49566) [#50850](https://github.com/pingcap/tidb/issues/50850) [#50855](https://github.com/pingcap/tidb/issues/50855) @[jiyfhust](https://github.com/jiyfhust)
    - (dup): release-7.1.4.md > 错误修复> TiDB - 修复通过 `tiup cluster upgrade/start` 方式进行滚动升级时，与 PD 交互出现问题可能导致 TiDB panic 的问题 [#50152](https://github.com/pingcap/tidb/issues/50152) @[zimulala](https://github.com/zimulala)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复执行包含 `ORDER BY` 的 `UNIQUE` 索引点查时可能报错的问题 [#49920](https://github.com/pingcap/tidb/issues/49920) @[jackysp](https://github.com/jackysp)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复常量传播在处理 `ENUM` 或 `SET` 类型时结果出错的问题 [#49440](https://github.com/pingcap/tidb/issues/49440) @[winoros](https://github.com/winoros)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复包含 Apply 操作的查询在报错 `fatal error: concurrent map writes` 后导致 TiDB 崩溃的问题 [#50347](https://github.com/pingcap/tidb/issues/50347) @[SeaRise](https://github.com/SeaRise)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复使用 `SET_VAR` 控制字符串类型的变量可能会失效的问题 [#50507](https://github.com/pingcap/tidb/issues/50507) @[qw4990](https://github.com/qw4990)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复表的 `ANALYZE` 任务统计的 `processed_rows` 可能超过表的总行数的问题 [#50632](https://github.com/pingcap/tidb/issues/50632) @[hawkingrei](https://github.com/hawkingrei)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复当 `HashJoin` 算子落盘失败时 goroutine 可能泄露的问题 [#50841](https://github.com/pingcap/tidb/issues/50841) @[wshwsh12](https://github.com/wshwsh12)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复 CTE 查询使用的内存超限时可能会导致 goroutine 泄露的问题 [#50337](https://github.com/pingcap/tidb/issues/50337) @[guo-shaoge](https://github.com/guo-shaoge)
    - (dup): release-7.5.1.md > 错误修复> TiDB - 修复使用聚合函数分组计算时可能报错 `Can't find column ...` 的问题 [#50926](https://github.com/pingcap/tidb/issues/50926) @[qw4990](https://github.com/qw4990)
    - (dup): release-7.1.4.md > 错误修复> TiDB - 修复当 `CREATE TABLE` 语句中包含特定分区或约束的表达式时，表名变更等 DDL 操作会卡住的问题 [#50972](https://github.com/pingcap/tidb/issues/50972) @[lcwangchao](https://github.com/lcwangchao)
    - (dup): release-7.1.4.md > 错误修复> TiDB - 修复 Grafana 监控指标 `tidb_statistics_auto_analyze_total` 没有显示为整数的问题 [#51051](https://github.com/pingcap/tidb/issues/51051) @[hawkingrei](https://github.com/hawkingrei)
    - (dup): release-7.1.4.md > 错误修复> TiDB - 修复修改变量 `tidb_server_memory_limit` 后，`tidb_gogc_tuner_threshold` 未进行相应调整的问题 [#48180](https://github.com/pingcap/tidb/issues/48180) @[hawkingrei]
    - (dup): release-7.1.4.md > 错误修复> TiDB - 修复当查询语句涉及 JOIN 操作时可能出现 `index out of range` 报错的问题 [#42588](https://github.com/pingcap/tidb/issues/42588) @[AilinKid](https://github.com/AilinKid)
    - (dup): release-7.1.4.md > 错误修复> TiDB - 修复当列的默认值被删除时，获取该列的默认值会报错的问题 [#50043](https://github.com/pingcap/tidb/issues/50043) [#51324](https://github.com/pingcap/tidb/issues/51324) @[crazycs520](https://github.com/crazycs520)

+ TiKV

    - note [#issue](链接) @[贡献者 GitHub ID](链接)
    - note [#issue](链接) @[贡献者 GitHub ID](链接)
    - (dup): release-7.5.1.md > 错误修复> TiKV - 修复开启 `tidb_enable_row_level_checksum` 可能导致 TiKV panic 的问题 [#16371](https://github.com/tikv/tikv/issues/16371) @[cfzjywxk](https://github.com/cfzjywxk)
    - (dup): release-7.1.4.md > 错误修复> TiKV - 修复休眠的 Region 在异常情况下未被及时唤醒的问题 [#16368](https://github.com/tikv/tikv/issues/16368) @[LykxSassinator](https://github.com/LykxSassinator)
    - (dup): release-7.1.4.md > 错误修复> TiKV - 通过在执行下线节点操作前检查该 Region 所有副本的上一次心跳时间，修复下线一个副本导致整个 Region 不可用的问题 [#16465](https://github.com/tikv/tikv/issues/16465) @[tonyxuqqi](https://github.com/tonyxuqqi)
    - (dup): release-7.1.4.md > 错误修复> TiKV - 修复 JSON 整型数值在大于 `INT64` 最大值但小于 `UINT64` 最大值时会被 TiKV 解析成 `FLOAT64` 导致结果和 TiDB 不一致的问题 [#16512](https://github.com/tikv/tikv/issues/16512) @[YangKeao](https://github.com/YangKeao)

+ PD

    - note [#issue](链接) @[贡献者 GitHub ID](链接)
    - note [#issue](链接) @[贡献者 GitHub ID](链接)
    - (dup): release-7.1.4.md > 错误修复> PD - 修复调用 `MergeLabels` 函数时存在数据竞争的问题 [#7535](https://github.com/tikv/pd/issues/7535) @[lhy1024](https://github.com/lhy1024)
    - (dup): release-7.1.4.md > 错误修复> PD - 修复调用 `evict-leader-scheduler` 接口时没有输出结果的问题 [#7672](https://github.com/tikv/pd/issues/7672) @[CabinfeverB](https://github.com/CabinfeverB)
    - (dup): release-7.5.1.md > 错误修复> PD - 修复 PD 监控项 `learner-peer-count` 在发生 Leader 切换后未同步旧监控值的问题 [#7728](https://github.com/tikv/pd/issues/7728) @[CabinfeverB](https://github.com/CabinfeverB)
    - (dup): release-7.1.4.md > 错误修复> PD - 修复 `watch etcd` 没有正确关闭导致内存泄露的问题 [#7807](https://github.com/tikv/pd/issues/7807) @[rleungx](https://github.com/rleungx)

+ TiFlash

    - note [#issue](链接) @[贡献者 GitHub ID](链接)
    - note [#issue](链接) @[贡献者 GitHub ID](链接)
    - (dup): release-7.5.1.md > 错误修复> TiFlash - 修复副本迁移时，因 TiFlash 与 PD 之间网络连接不稳定可能引发的 TiFlash panic 的问题 [#8323](https://github.com/pingcap/tiflash/issues/8323) @[JaySon-Huang](https://github.com/JaySon-Huang)
    - (dup): release-7.5.1.md > 错误修复> TiFlash - 修复慢查询导致内存使用显著增加的问题 [#8564](https://github.com/pingcap/tiflash/issues/8564) @[JinheLin](https://github.com/JinheLin)
    - (dup): release-7.5.1.md > 错误修复> TiFlash - 修复移除 TiFlash 副本后重新添加可能导致 TiFlash 数据损坏的问题 [#8695](https://github.com/pingcap/tiflash/issues/8695) @[JaySon-Huang](https://github.com/JaySon-Huang)
    - (dup): release-7.5.1.md > 错误修复> TiFlash - 修复在执行 PITR 恢复任务或 `FLASHBACK CLUSTER TO` 后，TiFlash 副本数据可能被意外删除，导致数据异常的问题 [#8777](https://github.com/pingcap/tiflash/issues/8777) @[JaySon-Huang](https://github.com/JaySon-Huang)
    - (dup): release-7.5.1.md > 错误修复> TiFlash - 修复在执行 `ALTER TABLE ... MODIFY COLUMN ... NOT NULL` 时，将原本可为空的列修改为不可为空之后，导致 TiFlash panic 的问题 [#8419](https://github.com/pingcap/tiflash/issues/8419) @[JaySon-Huang](https://github.com/JaySon-Huang)

+ Tools

    + Backup & Restore (BR)

        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - (dup): release-7.5.1.md > 错误修复> Tools> Backup & Restore (BR) - 修复在同一节点上更改 TiKV IP 地址导致日志备份卡住的问题 [#50445](https://github.com/pingcap/tidb/issues/50445) @[3pointer](https://github.com/3pointer)
        - (dup): release-7.5.1.md > 错误修复> Tools> Backup & Restore (BR) - 修复从 S3 读文件内容时出错后无法重试的问题 [#49942](https://github.com/pingcap/tidb/issues/49942) @[Leavrth](https://github.com/Leavrth)
        - (dup): release-7.5.1.md > 错误修复> Tools> Backup & Restore (BR) - 修复数据恢复失败后，使用断点重启报错 `the target cluster is not fresh` 的问题 [#50232](https://github.com/pingcap/tidb/issues/50232) @[Leavrth](https://github.com/Leavrth)
        - (dup): release-7.5.1.md > 错误修复> Tools> Backup & Restore (BR) - 修复停止日志备份任务导致 TiDB crash 的问题 [#50839](https://github.com/pingcap/tidb/issues/50839) @[YuJuncen](https://github.com/YuJuncen)
        - (dup): release-7.5.1.md > 错误修复> Tools> Backup & Restore (BR) - 修复由于某个 TiKV 节点缺少 Leader 导致数据恢复变慢的问题 [#50566](https://github.com/pingcap/tidb/issues/50566) @[Leavrth](https://github.com/Leavrth)
        - (dup): release-7.5.1.md > 错误修复> Tools> Backup & Restore (BR) - 修复全量恢复指定 `--filter` 选项后，仍然要求目标集群为空的问题 [#51009](https://github.com/pingcap/tidb/issues/51009) @[3pointer](https://github.com/3pointer)

    + TiCDC

        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - (dup): release-7.5.1.md > 错误修复> Tools> TiCDC - 修复使用 storage sink 时，在存储服务生成的文件序号可能出现回退的问题 [#10352](https://github.com/pingcap/tiflow/issues/10352) @[CharlesCheung96](https://github.com/CharlesCheung96)
        - (dup): release-7.5.1.md > 错误修复> Tools> TiCDC - 修复并发创建多个 changefeed 时 TiCDC 返回 `ErrChangeFeedAlreadyExists` 错误的问题 [#10430](https://github.com/pingcap/tiflow/issues/10430) @[CharlesCheung96](https://github.com/CharlesCheung96)
        - (dup): release-7.5.1.md > 错误修复> Tools> TiCDC - 修复在 `ignore-event` 中设置了过滤掉 `add table partition` 事件后，TiCDC 未将相关分区的其它类型 DML 变更事件同步到下游的问题 [#10524](https://github.com/pingcap/tiflow/issues/10524) @[CharlesCheung96](https://github.com/CharlesCheung96)
        - (dup): release-7.5.1.md > 错误修复> Tools> TiCDC - 修复上游表执行了 `TRUNCATE PARTITION` 后 changefeed 报错的问题 [#10522](https://github.com/pingcap/tiflow/issues/10522) @[sdojjy](https://github.com/sdojjy)
        - (dup): release-7.1.4.md > 错误修复> Tools> TiCDC - 修复恢复 changefeed 时 changefeed 的 `checkpoint-ts` 小于 TiDB 的 GC safepoint，没有及时报错 `snapshot lost caused by GC` 的问题 [#10463](https://github.com/pingcap/tiflow/issues/10463) @[sdojjy](https://github.com/sdojjy)
        - (dup): release-7.1.4.md > 错误修复> Tools> TiCDC - 修复 TiCDC 在开启单行数据正确性校验后由于时区不匹配导致 `TIMESTAMP` 类型 checksum 验证失败的问题 [#10573](https://github.com/pingcap/tiflow/issues/10573) @[3AceShowHand](https://github.com/3AceShowHand)
        - (dup): release-7.5.1.md > 错误修复> Tools> TiCDC - 修复 Syncpoint 表可能被错误同步的问题 [#10576](https://github.com/pingcap/tiflow/issues/10576) @[asddongmen](https://github.com/asddongmen)
        - (dup): release-7.5.1.md > 错误修复> Tools> TiCDC - 修复当使用 Apache Pulsar 作为下游时，无法正常启用 OAuth2.0、TLS 和 mTLS 的问题 [#10602](https://github.com/pingcap/tiflow/issues/10602) @[asddongmen](https://github.com/asddongmen)

    + TiDB Data Migration (DM)

        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - note [#issue](链接) @[贡献者 GitHub ID](链接)

    + TiDB Lightning

        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - (dup): release-7.1.4.md > 错误修复> Tools> TiDB Lightning - 修复在扫描数据文件时，遇到不合法符号链接文件而报错的问题 [#49423](https://github.com/pingcap/tidb/issues/49423) @[lance6716](https://github.com/lance6716)
        - (dup): release-7.1.4.md > 错误修复> Tools> TiDB Lightning - 修复当 `sql_mode` 中不包含 `NO_ZERO_IN_DATE` 时，TiDB Lightning 无法正确解析包含 `0` 的日期值的问题 [#50757](https://github.com/pingcap/tidb/issues/50757) @[GMHDBJD](https://github.com/GMHDBJD)

    + Dumpling

        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - note [#issue](链接) @[贡献者 GitHub ID](链接)

    + TiUP

        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - note [#issue](链接) @[贡献者 GitHub ID](链接)

    + TiDB Binlog

        - note [#issue](链接) @[贡献者 GitHub ID](链接)
        - note [#issue](链接) @[贡献者 GitHub ID](链接)

## Other dup notes

- (dup): release-7.5.1.md > 兼容性变更 - 在安全增强模式 (SEM) 下禁止设置 [`require_secure_transport`](https://docs.pingcap.com/zh/tidb/v7.5/system-variables#require_secure_transport-从-v610-版本开始引入) 为 `ON`，避免用户无法连接的问题 [#47665](https://github.com/pingcap/tidb/issues/47665) @[tiancaiamao](https://github.com/tiancaiamao)
- (dup): release-7.6.0.md > # 稳定性 * 跨数据库绑定执行计划 [#48875](https://github.com/pingcap/tidb/issues/48875) @[qw4990](https://github.com/qw4990)
- (dup): release-7.6.0.md > # 性能> -log-file restorefull.log * 默认开启 Titan 引擎 [#16245](https://github.com/tikv/tikv/issues/16245) @[Connor1996](https://github.com/Connor1996) @[v01dstar](https://github.com/v01dstar) @[tonyxuqqi](https://github.com/tonyxuqqi)

## 贡献者

感谢来自 TiDB 社区的贡献者们：

- [贡献者 GitHub ID]()
