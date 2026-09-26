# artifacts/deprecated — 已作废产物

这里的文件**不可作为证据引用**，保留只为防止重犯同一类错误。每个文件必须在下表登记"错在哪、被谁取代"。

| 文件 | 作废原因 | 取代它的证据件 |
|---|---|---|
| `_INVALID_decoy-pdata-parse_do-not-use.tsv` | 按**段表里名为 `.pdata` 的区间**（VA 0x14116d000，`SizeOfRawData=0`）解析异常表得到 1,696 个"函数"，其长度是 41 亿字节量级、全不合法。真实异常目录在 `DataDirectory[3] = RVA 0x3f5d150 size 0x79e0`，落在有磁盘数据的 `.)Bu` 节里。该段表名是壳留下的诱饵。 | `artifacts/evidence/genB_functions_from_pdata.tsv`（2,593 条合法 RUNTIME_FUNCTION） |

新增条目时的格式要求：一行一条，必须写"错在哪"而不只是"不用了"——否则下一个人无法判断它是否其实还能用。
