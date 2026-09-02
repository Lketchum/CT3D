# 投影到三维重建 — DBT 起点项目

> 从 2D 投影图像重建 3D 结构，逻辑上与 CT 重建完全一致。  
> 关联战略文档：[双主线战略-三维重建×AI智能化](../职业发展方向分析/双主线战略-三维重建×AI智能化.md)

## 为什么从这里开始

| 维度 | 说明 |
|------|------|
| **核心问题** | 给定一组 2D 投影，如何通过算法恢复 3D 体数据/表面 |
| **与 CT 的关系** | DBT 的 FBP / SART / MLEM 与 CT 重建在数学与工程上同源 |
| **与背景契合** | DR Tomo 经验可直接迁移到 DBT 数据与采集几何 |
| **可复用范式** | RadSurf（2D X 光 → 3D 表面）思路可横向对比学习 |

## 学习路径（三阶段）

```
Phase 1 — 传统重建（当前）
  Shepp-Logan phantom → BP / FBP → 对照 MATLAB DBT 工具箱
        ↓
Phase 2 — 真实 DBT 数据
  TCIA 乳腺癌筛查 DBT → DICOM 读取 → 完整重建管线
        ↓
Phase 3 — 前沿扩展
  DiffDRR（可微渲染）→ RadSurf（DL 单视图重建）
```

详细任务清单见 [docs/learning-path.md](docs/learning-path.md)。

## 目录结构

```
投影到三维重建-DBT起点/
├── README.md              # 本文件
├── docs/
│   ├── learning-path.md   # 分阶段学习任务
│   └── resources.md       # 数据集与开源工具链接
├── data/
│   ├── raw/               # 原始 DICOM / 投影数据（不提交 git）
│   └── processed/         # 预处理后的体数据、投影栈
├── notebooks/             # 探索性实验（phantom、可视化）
├── src/
│   ├── io/                # DICOM / 投影数据读写
│   ├── reconstruction/    # BP、FBP、迭代重建
│   └── visualization/     # 切片与体渲染
├── references/            # 论文笔记、工具箱阅读记录
└── scripts/               # 下载、批处理脚本
```

## 立即着手（P0）

- [ ] 阅读 [LAVI-USP/DBT-Reconstruction](https://github.com/LAVI-USP/DBT-Reconstruction) 的 `FBP.m` / `SART.m`，理解几何参数与反投影流程
- [ ] 在 `notebooks/` 用 Python 实现 Shepp-Logan phantom + 2D FBP，与工具箱结果对照
- [ ] 注册 [TCIA](https://www.cancerimagingarchive.net/) 账号，申请下载乳腺癌筛查 DBT 数据集
- [ ] 用 3D Slicer 打开一份 DBT DICOM，熟悉体数据维度与投影几何

## 关联资源

完整链接与说明见 [docs/resources.md](docs/resources.md)。

| 类别 | 资源 |
|------|------|
| **主数据** | TCIA 乳腺癌筛查 DBT（22,032 次扫描） |
| **主工具** | [DBT-Reconstruction](https://github.com/LAVI-USP/DBT-Reconstruction)（BP / FBP / SART，MATLAB） |
| **对照参考** | [RadSurf](https://github.com/IGRS-medical-imaging/RadSurf)（475 CT → 11,400 DRR-网格对） |
| **可微渲染** | [DiffDRR](https://github.com/eigenvivek/DiffDRR)（CT → DRR，PyTorch） |
| **扩展 CT 数据** | MAGIC-CT、CT4Harmonization-Multicentric |

## 环境建议

```bash
# Python 侧（原型与可视化）
python -m venv .venv
source .venv/bin/activate
pip install numpy scipy matplotlib pydicom SimpleITK torchio

# MATLAB 侧（对照 DBT 工具箱）
# 需要 MATLAB R2015a+，可选 CUDA 加速
```

---

*创建日期：2026-09-01*
