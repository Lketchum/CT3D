# 教学分区 `teach/`

面向**手动改代码学习**的 CT **三维可视化**核心数学。  
与 `matlab/`（Agent 搭的工作站 / 实验脚本）分开：这里尽量**不调用** `volshow` 等黑盒，把公式写在可见处。

## 和 `matlab/` 的关系

| | `matlab/` | `teach/` |
|--|-----------|----------|
| 目的 | 快速出结果、工作站交互 | 抠通公式、自己改参数 |
| 风格 | 工程封装 | 短脚本 + `lib/` 透明实现 |
| 黑盒 | 可用 IPT / volshow | 尽量手写；允许 `dicomread` / `interp3` 作对照 |

## 推荐路线：三维可视化（默认）

按这个顺序学即可，**不必做 t04**：

| 序号 | 脚本 | 核心问题 |
|------|------|----------|
| 0 | `t00_load_series.m` | 多张 DICOM 如何堆成三维数组 |
| 1 | `t01_hu_and_window.m` | 存盘值 → HU → 窗宽窗位 → 显示灰度 |
| 2 | `t02_isotropic_resample.m` | Z 更粗时如何插成正方体素（显示不变形） |
| 3 | `t03_mpr_geometry.m` | 横/冠/矢 + 任意法向量切面（MPR） |
| 5 | `t05_marching_cubes_lite.m` | 等值面 → 三角网格（骨骼/体表 3D 模型） |

对应练习：`exercises/ex01`、`ex02`、`ex03`、`ex05`。

```matlab
cd('d:/AI_assist_project/CT3D/teach')
t00_load_series
t01_hu_and_window
t02_isotropic_resample
t03_mpr_geometry
t05_marching_cubes_lite   % skip t04
```

## 可选：t04 光线投射（可后置）

`t04_ray_casting.m` **不是**「X 光物理投影 → FBP 重建」那条线（那是 `matlab/p01`–`p04`）。

它属于**可视化里的体绘制入门**：已经有三维体之后，沿视线采样得到一张 2D 图（如 MIP）。  
和三维网格 / MPR 相比，对「先做出可交互 3D 模型」不是刚需；等 MPR + 表面做熟了，再学体绘制时再打开即可。练习 `ex04` 同样可选。

## 每课结构

1. **公式**（注释里）  
2. **可运行参考实现**（`lib/`）  
3. **STUDENT 区**（`>>> STUDENT`：改参数或重写）  
4. 图输出到 `data/processed/teach/`

## 目录

```
teach/
├── README.md
├── t00_load_series.m
├── t01_hu_and_window.m
├── t02_isotropic_resample.m
├── t03_mpr_geometry.m
├── t04_ray_casting.m          % 可选（体绘制 / MIP）
├── t05_marching_cubes_lite.m
├── lib/
└── exercises/
```

需要本机 `data/OrigCTData` 中有轴位 CT。
