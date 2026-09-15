# 开源数据与工具资源

## 主线路：DBT 投影重建

### 数据集

| 名称 | 规模 | 说明 | 链接 |
|------|------|------|------|
| **Breast Cancer Screening DBT** | 22,032 次扫描 | TCIA 公开发布的大规模 DBT 数据集；压缩 DICOM，每文件含完整 3D 体积 | [TCIA Collections](https://www.cancerimagingarchive.net/collections/) — 搜索 "DBT" 或 "digital breast tomosynthesis" |
| **BR3D Phantom** | 体模数据 | DBT-Reconstruction 工具箱验证用物理体模，适合算法对齐 | 见 [DBT-Reconstruction](https://github.com/LAVI-USP/DBT-Reconstruction) README |

> **下载提示：** TCIA 需注册账号，部分集合需提交 Data Use Agreement。建议先用工具箱内置 Shepp-Logan phantom，再下载真实数据。

### 重建工具箱

| 名称 | 语言 | 算法 | 平台 | 链接 |
|------|------|------|------|------|
| **DBT-Reconstruction (LAVI-USP)** | MATLAB | BP, FBP, SART | Win / Linux / macOS | https://github.com/LAVI-USP/DBT-Reconstruction |
| **ReconDBT (FDA/DIDSR)** | MATLAB | FBP, SART, MLEM | Linux / macOS only | https://github.com/DIDSR/ReconDBT |

**推荐优先：** LAVI-USP 版本 — 跨平台、几何可配置、含 CUDA 加速选项。Windows 上用 MATLAB 本体；克隆命令：`scripts/clone_dbt_toolbox.ps1`。本地阅读笔记见 [references/dbt-toolbox-notes.md](../references/dbt-toolbox-notes.md)。

---

## 对照参考：RadSurf（2D X 光 → 3D 表面）

| 项目 | 说明 | 链接 |
|------|------|------|
| **RadSurf** | 475 个 CT 扫描，每 CT 生成 24 张 DRR，共 11,400 对 DRR-网格 | https://github.com/IGRS-medical-imaging/RadSurf |
| **数据集** | Google Drive 直链 | https://drive.google.com/drive/folders/1YBzQlRE8mZOfmKDpoc9omabz6GCIIJbH |
| **3D-ReVert** | 基于 RadSurf 数据的 DL 单视图椎骨重建 | https://github.com/IGRS-medical-imaging/3D-ReVert |

**与 DBT 的差异：** 模态（X 光 vs 断层合成）、部位（脊椎 vs 乳腺）不同，但「投影 → 3D」问题形式一致。

---

## 可微渲染：DiffDRR

| 项目 | 说明 | 链接 |
|------|------|------|
| **DiffDRR** | PyTorch 可微 DRR 生成器；支持 CT 体积 → DRR，及基于梯度的体积重建 | https://github.com/eigenvivek/DiffDRR |
| **文档** | API 与 tutorial | https://vivekg.dev/DiffDRR/ |
| **重建教程** | 可微渲染逆向恢复 3D 体积 | https://vivekg.dev/DiffDRR/tutorials/reconstruction.html |

**用途：** 理解成像几何、投影物理，以及「正向渲染 + 反向优化」的现代重建思路。

---

## 扩展 CT 数据集（Phase 2+ 或横向对比）

| 名称 | 规模 | 特点 | 链接 |
|------|------|------|------|
| **MAGIC-CT** | 562 例腹部增强 CT + 3D 标注 + 492 份报告 | 多模态三维重建研究 | 搜索 MAGIC-CT benchmark |
| **CT4Harmonization-Multicentric** | 268 序列，13 种扫描仪，8 家机构 | 测试重建算法跨设备普适性 | 搜索 CT4Harmonization |
| **LIDC-IDRI** | 1018 例胸部 CT | 经典公开 CT，适合 3D 可视化练习 | [TCIA LIDC-IDRI](https://www.cancerimagingarchive.net/collection/lidc-idri/) |
| **MultiCaRe** | 76,000+ 报告，139,000+ 图像 | 多专科多模态，扩展视野 | 搜索 MultiCaRe dataset |

---

## 可视化与 IO 工具

| 工具 | 用途 |
|------|------|
| [3D Slicer](https://www.slicer.org/) | 打开 DICOM、体数据可视化、DRR 生成 |
| [ITK / SimpleITK](https://simpleitk.org/) | Python/C++ 医学影像 IO 与滤波 |
| [VTK](https://vtk.org/) | 3D 渲染与可视化 |
| [pydicom](https://pydicom.github.io/) | Python DICOM 解析 |
| [TorchIO](https://torchio.readthedocs.io/) | PyTorch 医学影像（DiffDRR 依赖） |

---

## 推荐阅读

1. Levakhina, Y. — *Three-Dimensional Digital Tomosynthesis* (2014) — DBT-Reconstruction 工具箱参考书籍
2. Kak & Slaney — *Principles of Computerized Tomographic Imaging* — CT/投影重建经典
3. RadSurf 论文 — 单视图 3D 重建与 DRR 合成 pipeline
