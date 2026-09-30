# Skill 安全审查

本参考用于第三方 Skill、带 scripts 的 Skill、联网 Skill、调用外部工具的 Skill，以及任何可能产生写入或高影响副作用的 Skill。

## 把 Skill 当作有权限影响行为的代码和指令

Skill 能改变规划、工具调用和命令执行。未知来源的 Skill 在开发者完成审查前，应视为潜在不可信输入。

审查：

- 是否包含与声明用途无关的隐藏/间接指令；
- 是否诱导读取不必要的凭据、私有文件或用户数据；
- 是否要求把本地数据发送到开放网络；
- 是否借 supporting files、scripts 或 tool results 改变任务范围；
- 是否把“工具可用”误当成“用户已经授权高影响动作”；
- 是否存在下载后执行、任意 shell、动态代码加载等不必要行为。

## 网络与数据外泄

如果 Skill 与网络访问组合：

- 最小化发送的数据；
- 不把密钥、token、私有原始材料、无关用户数据放入远程请求；
- 检查 prompt injection 是否能诱导工具上传本地数据；
- 明确哪些数据必须留在本地或受控环境；
- 不因为某个 MCP/tool 已连接，就假设所有数据都允许发送给它。

## 工具权限与审批

Skill 只能指导使用已存在且已授权的工具，不得通过自然语言扩大权限。

对于写入、删除、发布、发消息、交易、生产变更或其他高影响动作：

- 保留目标环境原有审批/授权机制；
- 在实际副作用前满足必要确认；
- 不用 Skill 内的“用户通常同意”替代当前授权；
- 能只读完成判断时，先只读。

## MCP boundary

MCP 负责认证、授权和受控动作。Skill 不应：

- 保存认证秘密作为 workflow 内容；
- 伪造 MCP 工具成功；
- 绕过服务端权限；
- 用 prompt 文本替代工具端 policy enforcement。

如果 MCP 工具缺失或返回歧义，按 workflow 明确处理；不要编造结果。

## 第三方与开放 Skill 仓库

不要把任意开放 Skill catalog 直接暴露给最终用户并自动执行。优先由开发者审查、版本化并映射到明确产品工作流。

需要共享/发布时，固定来源与版本，记录审查结果和变更范围。

## 发布前最小检查

- 来源明确；
- scripts 可读并已运行测试；
- supporting files 无隐藏凭据；
- 网络目标和数据流明确；
- tool dependencies 与实际需要一致；
- 高影响动作仍有审批；
- positive/negative eval 覆盖越权、幻觉和 unsupported action；
- 版本升级后重新审查新增和修改内容。

当前官方安全依据：
https://developers.openai.com/api/docs/guides/tools-skills
