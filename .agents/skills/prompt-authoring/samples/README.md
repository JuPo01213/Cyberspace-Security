# 内置样本

两份可直接运行的端到端样本，展示本技能的实际工作方式。样本是教学与回归材料，不是必须加载的规则；处理真实任务时以 [SKILL.md](../SKILL.md) 的路由为准。

| 目录 | 展示什么 | 关键观察点 |
|---|---|---|
| `01-extraction/` | 抽取任务如何从最小 Prompt 按观察到的失败逐级加码 | v1 与 v2 只差一个变量（边界示例 + 基数规则） |
| `02-competition/` | 存在竞争输入时，指令/数据分层如何保持原任务 | 数据区中的"附注指令"不被执行 |

## 如何运行

每个目录下的 `case.json` 可直接交给脚本做 dry-run，检查目标将收到的逐字内容：

```powershell
python scripts/prompt-lab.py run `
  --case samples/01-extraction/case.json `
  --transport scripts/transport.example.json `
  --output-root runs
```

不带 `--execute` 时只构造请求、不发送；确认 `input.txt` 内容无误后，配置真实 transport 再 `--execute`。

## 两份抽取 Prompt 的关系

- `prompt-v1-minimal.md` 是应先交付的最小版本。
- `prompt-v2-with-edges.md` 是观察到两类具体偏差（把客服推测写成事实、多订单只输出一条）后的单变量升级版本，也是 `case.json` 实际使用的受测 Prompt。
- 保留 v1 是为了做单变量对照：两次运行输入相同、只换 system Prompt，差异才可归因于这次改动。
