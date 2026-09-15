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
CT3D/
├── README.md
├── docs/
├── teach/                 # 【教学分区】手写核心数学，可手动改代码学习
│   ├── README.md
│   ├── t00..t05_*.m
│   ├── lib/
│   └── exercises/
├── matlab/                # Agent 工作站 / 实验脚本（对照用）
│   ├── p01..p06_*.m
│   ├── viewer/
│   └── recon/
├── vendor/
├── data/
├── notebooks/
├── src/
├── references/
└── scripts/
```

## 两条学习线

| 线 | 入口 | 适合 |
|----|------|------|
| **教学（推荐先抠公式）** | [`teach/README.md`](teach/README.md) | HU/窗宽、各向同性重采样、MPR、光线投射、Marching Cubes |
| **工作站 / 实验** | [`matlab/README.md`](matlab/README.md) | 交互切层、快速出图、FBP 对照 |
## 立即着手（P0）

当前按 **MATLAB 先复现、Python 后对照** 推进（本机 MATLAB R2025a + Image Processing Toolbox）。

- [x] 搭建目录；克隆 [LAVI-USP/DBT-Reconstruction](https://github.com/LAVI-USP/DBT-Reconstruction) 到 `vendor/`
- [x] `matlab/p01_shepp_logan_fbp.m` — 2D Shepp-Logan，BP vs FBP + RMSE/SSIM
- [x] `matlab/p02_limited_angle_dbt.m` — 全角度 vs 有限角度（DBT 几何直觉）
- [ ] 阅读工具箱 `FBP.m` / `SART.m` / `ParameterSettings_*.m`（笔记：[references/dbt-toolbox-notes.md](references/dbt-toolbox-notes.md)）
- [x] 运行 `matlab/p03_run_lavi_phantom.m`，对照半锥束 3D FBP
- [x] `matlab/p04_ct_dicom_fbp.m` — 从 `data/OrigCTData` 加载真实轴位 CT 并复现 FBP
- [x] `matlab/p05_ct_slice_viewer.m` — 三维体积工作站：加载、三平面显示、切片操作
- [ ] 注册 [TCIA](https://www.cancerimagingarchive.net/) 账号，申请乳腺癌筛查 DBT（Phase 2）
- [ ] 用 3D Slicer 打开一份 DBT DICOM

运行说明见 [matlab/README.md](matlab/README.md)。

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

# MATLAB 侧（Phase 1 主路径）
# 需要 MATLAB R2015a+ 与 Image Processing Toolbox
# 可选：克隆工具箱
#   powershell -File scripts/clone_dbt_toolbox.ps1
```

---

*创建日期：2026-09-01*
