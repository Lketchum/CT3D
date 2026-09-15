# LAVI-USP DBT-Reconstruction 阅读笔记

日期：2026-09-02  
仓库：`vendor/DBT-Reconstruction`（[GitHub](https://github.com/LAVI-USP/DBT-Reconstruction)）

## 入口与调用链

```
Reconstruction.m          GUI：Clinical DICOM 或 Shepp-Logan
  ├─ ParameterSettings_*  几何（Phantom / GE / Hologic）
  ├─ phantom3d            3D 改进 Shepp-Logan
  ├─ projection           半锥束体素驱动投影（slice-wise interp2）
  └─ FBP / SART / SIRT / MLEM
        FBP.m
          ├─ filterProj   锥束加权 + Ram-Lak（Feldkamp / Fessler）
          └─ backprojection
        SART.m
          └─ 每视角：proj 残差 / proj_norm → BP / vol_norm → 加回体积
```

`FBP.m` 的 `filterType`：`'FBP'` 先滤波再反投影；`'BP'` 跳过 `filterProj`，即纯反投影。

本仓库用 `matlab/p03_run_lavi_phantom.m` 跳过 GUI，直接走 Phantom → projection → FBP。

## 几何参数（对照三套配置）

距离符号（工具箱命名，单位 mm）：

| 符号 | 含义 |
|------|------|
| `DSD` | 源到探测器 |
| `DSO` | 源到物体顶面 |
| `DDR` | 探测器到旋转枢轴 |
| `DSR` | 源到枢轴 = `DSD - DDR` |
| `DAG` | 空气间隙（物体底到探测器一侧） |
| `tubeAngle` / `nProj` | 球管摆角范围与投影数 |
| `nx,ny,nz` / `dx,dy,dz` | 重建体素网格 |
| `nu,nv` / `du,dv` | 探测器像素 |

| | Phantom | GE Senographe | Hologic |
|--|---------|---------------|---------|
| `DSD` | 6600 | 660 | 见 `ParameterSettings_Hologic.m` |
| `DSO` | 5100 | 584.5 | |
| `DDR` | 400 | 40 | |
| `DAG` | 220 | 22 | |
| 体素 | 128³，dx=dy=1，**dz=10** | 1058×1978×107，0.1×0.1×0.5 | 临床尺寸 |
| 探测器 | 280×350，1 mm | 2394×3062，0.1 mm | |
| `nProj` | 9 | 9 | 15 |
| `tubeAngle` | **2.5°** | **25°** | **15°**（探测器另偏 4.2°） |

Phantom 的距离大约是 GE 的 10 倍，体素也更粗，用于数值演示而不是物理 1:1。GE 的 25° / 9 投影更接近临床 DBT 扫角。

坐标系要点（`projection.m` / `backprojection.m`）：

- 半锥束：球管绕枢轴摆，探测器可固定（`detAngle=0`，GE/Phantom）或小幅跟随（Hologic）。
- 物体 X 从胸壁侧递减编号（`xs = (nx-1:-1:0)*dx`），源在一侧。
- 每层 `z` 用相似三角形把体素投到探测器 `(u,v)`，再 `interp2`。

## 算法对照

| 方法 | 工具箱做法 | 2D 对照（`matlab/01`） |
|------|------------|------------------------|
| BP | 各视角反投影直接累加 | `iradon(..., 'none')`，图像糊 |
| FBP | `filterProj`（距离加权 + Ram-Lak + cutoff）再 BP | 先 `apply_ramp_filter` 再反投影 |
| SART | 每视角：投影残差归一化后反投影更新 | Phase 1 暂不实现 |

`filterProj.m` 的加权：`DSO / sqrt(DSD² + u² + v²)`（Fessler 锥束权）。二维平行束实验里没有这项，只保留 Ram-Lak。

## 对重建质量的直观影响

- **扫角变窄**（2.5° vs 180°）：傅里叶空间缺一大块，深度方向模糊、条状伪影。见 `matlab/p02_limited_angle_dbt.m`。
- **`dz` 远大于 `dx`**：Phantom 默认层厚 10 mm，深度分辨率本来就粗。
- **`cutoff < 1`**：压高频噪声，同时损失锐度。工具箱默认 0.75。
- **投影数**：9 张只是离散采样；SART 比 FBP 更能消化稀疏角，但更慢。

## 本机复现顺序

1. `matlab/p01_shepp_logan_fbp.m` — 先建立「滤波补偿 1/|ω|」的直觉  
2. `matlab/p02_limited_angle_dbt.m` — 再看有限角为什么不是 CT  
3. `matlab/p03_run_lavi_phantom.m` — 接到工具箱半锥束几何  
4. 读 `FBP.m` / `SART.m` / `filterProj.m`，对照本笔记
