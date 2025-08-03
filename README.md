# PomeoGo

一个全平台原生项目任务管理应用，专为个人和团队项目管理而设计。PomeoGo 结合了简洁的用户界面和强大的项目管理功能，旨在提供比 Apple Reminders 更专业的任务管理体验。

## 🚀 功能特性

### 核心功能
- **任务管理**: 创建、编辑、删除任务，支持优先级、状态、截止日期设置
- **项目管理**: 组织任务到不同项目中，支持项目归档和颜色标识
- **史诗管理**: 高级项目管理功能，支持大型项目的分层组织
- **智能列表**: 今日任务、计划任务、已完成任务等智能筛选视图
- **标签系统**: 灵活的任务标签分类和管理
- **附件支持**: 为任务添加文件附件
- **检查清单**: 任务内嵌检查清单功能
- **时间追踪**: 任务时间估算和实际耗时记录

### 高级功能
- **重复任务**: 支持多种重复模式（每日、每周、每月等）
- **位置提醒**: 基于地理位置的智能提醒
- **依赖关系**: 任务间的依赖关系管理
- **数据持久化**: 本地数据存储和缓存管理
- **响应式设计**: 适配 macOS、iOS、iPadOS 多平台

## 🏗️ 技术架构

### 架构模式
- **MVVM 架构**: 使用 SwiftUI 和 Combine 框架
- **Repository 模式**: 数据访问层抽象
- **Service 层**: 业务逻辑和外部服务集成
- **依赖注入**: 松耦合的组件设计

### 核心技术栈
- **SwiftUI**: 现代化 UI 框架
- **Combine**: 响应式编程
- **Foundation**: 核心系统框架
- **UserDefaults**: 本地数据存储
- **FileManager**: 文件系统管理

### 项目结构
```
pomeogo/
├── Models/              # 数据模型
│   ├── Core/           # 核心模型 (Task, Project, Epic, Tag, Attachment)
│   ├── DTOs/           # 数据传输对象
│   └── Protocols/      # 协议定义
├── ViewModels/         # 视图模型层
├── Views/              # SwiftUI 视图组件
│   ├── Project/        # 项目相关视图
│   ├── Task/           # 任务相关视图
│   ├── Sheets/         # 弹窗表单
│   └── TextEditor/     # 文本编辑器组件
├── Services/           # 服务层
│   ├── Data/           # 数据管理服务
│   ├── FileManager/    # 文件管理服务
│   └── Sync/           # 同步服务
├── Repositories/       # 数据访问层
├── Persistence/        # 持久化层
└── pomeogoTests/       # 单元测试
```

## 📱 支持的平台

- **macOS**: 14.0+ (Sonoma)
- **iOS**: 17.0+ 
- **iPadOS**: 17.0+

## 🛠️ 开发环境要求

- **Xcode**: 15.0+
- **Swift**: 5.9+
- **macOS**: 14.0+ (用于开发)
- **iOS Simulator**: 17.0+ (用于测试)

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone [项目地址]
cd PomeoGo
```

### 2. 打开项目
```bash
open pomeogo.xcodeproj
```

### 3. 选择目标平台
- 在 Xcode 中选择目标设备或模拟器
- 支持 macOS、iPhone、iPad 多平台

### 4. 构建和运行
```bash
# 使用 Xcode 构建 (⌘+R)
# 或使用命令行
xcodebuild -project pomeogo.xcodeproj -scheme pomeogo -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### 5. 运行测试
```bash
# 在 Xcode 中运行测试 (⌘+U)
# 或使用命令行
xcodebuild -project pomeogo.xcodeproj -scheme pomeogo -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## 📖 使用指南

### 基本操作

#### 创建任务
1. 点击工具栏的 "+" 按钮
2. 选择 "新建任务"
3. 填写任务标题、描述、优先级等信息
4. 设置截止日期和提醒时间
5. 点击 "保存"

#### 创建项目
1. 点击工具栏的 "+" 按钮
2. 选择 "新建项目"
3. 填写项目名称、描述
4. 选择项目颜色
5. 点击 "保存"

#### 管理史诗
1. 点击工具栏的 "+" 按钮
2. 选择 "新建史诗"
3. 填写史诗名称、描述
4. 选择史诗颜色
5. 将相关项目关联到史诗

### 高级功能

#### 任务依赖关系
- 在任务详情中设置依赖任务
- 系统会自动检查依赖关系
- 依赖任务完成前，当前任务无法标记为完成

#### 重复任务
- 设置任务重复模式（每日、每周、每月等）
- 配置重复间隔和结束日期
- 系统自动生成重复任务实例

#### 位置提醒
- 启用位置提醒功能
- 设置提醒位置和范围
- 到达指定位置时自动提醒

## 🧪 测试

项目包含完整的单元测试覆盖：

```bash
# 运行所有测试
xcodebuild test -project pomeogo.xcodeproj -scheme pomeogo

# 运行特定测试
xcodebuild test -project pomeogo.xcodeproj -scheme pomeogo -only-testing:pomeogoTests/TaskViewModelTests
```

### 测试覆盖范围
- **数据模型测试**: Task、Project、Epic 等核心模型
- **视图模型测试**: TaskViewModel、ProjectViewModel 等
- **仓储层测试**: 数据访问层功能验证
- **服务层测试**: 业务逻辑和集成测试
- **集成测试**: 端到端功能验证

## 🔧 开发指南

### 代码规范
- 遵循 Swift 官方编码规范
- 使用 SwiftLint 进行代码质量检查
- 所有公共 API 必须有文档注释
- 使用 SwiftUI 预览进行 UI 开发

### 提交规范
```
feat: 新功能
fix: 修复问题
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建过程或辅助工具的变动
```

### 分支管理
- `main`: 主分支，稳定版本
- `develop`: 开发分支
- `feature/*`: 功能分支
- `hotfix/*`: 紧急修复分支

## 📊 项目状态

### 已完成功能 ✅
- [x] 核心数据模型 (Task, Project, Epic, Tag, Attachment)
- [x] MVVM 架构实现
- [x] SwiftUI 用户界面
- [x] 本地数据持久化
- [x] 任务和项目管理
- [x] 智能列表和筛选
- [x] 单元测试覆盖
- [x] 多平台支持

### 开发中功能 🚧
- [ ] iCloud 同步集成
- [ ] Apple Reminders 集成
- [ ] Apple Calendar 集成
- [ ] 数据导入导出

### 计划功能 📋
- [ ] 甘特图视图
- [ ] 时间线视图
- [ ] 统计报表
- [ ] 团队协作
- [ ] 快捷指令支持
- [ ] 语音输入
- [ ] AI 助手集成

## 🤝 贡献指南

由于这是一个私有项目，贡献主要通过内部团队协作进行。如需参与开发，请联系项目维护者。

### 开发流程
1. 创建功能分支
2. 实现功能并编写测试
3. 确保所有测试通过
4. 提交代码审查
5. 合并到主分支

## 📄 许可证

本项目为私有项目，版权所有。未经授权，不得复制、分发或修改。

## 📞 联系方式

如有问题或建议，请联系项目维护团队。

---

**PomeoGo** - 让项目管理更简单、更高效 