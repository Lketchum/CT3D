# 学习路径与里程碑

## Phase 0：教学分区 — 三维可视化核心数学（可改代码）

**目标：** 不依赖 `volshow` 等黑盒，手写 HU/窗宽、重采样、MPR、等值面网格。详见 [teach/README.md](../teach/README.md)。

**主线（推荐）：**

- [ ] `teach/t00_load_series.m` — 多张 DICOM 堆成三维（存盘值）
- [ ] `teach/t01_hu_and_window.m` — Rescale → HU → 窗宽窗位 → 8-bit
- [ ] `teach/t02_isotropic_resample.m` — 各向同性重采样
- [ ] `teach/t03_mpr_geometry.m` — 轴位/冠/矢 + 任意法向量切面
- [ ] `teach/t05_marching_cubes_lite.m` — 等值面网格（MC 思想）
- [ ] `teach/exercises/ex01,ex02,ex03,ex05` — 填空练习

**可选（体绘制，非重建）：**

- [ ] `teach/t04_ray_casting.m` — 光线投射 MIP（可视化，可后学）

---

## Phase 1：原理打底 + Phantom 实验（第 1–4 周）

**目标：** 亲手跑通「投影 → 反投影 → 3D 体」，建立与 CT 重建一致的心智模型。

### 理论

- [ ] Radon 变换与 FBP 公式推导（参考《Computed Tomography Principles...》）
- [ ] DBT 与 CT 的几何差异：有限角度、半锥束、圆形/非圆形轨迹
- [ ] 三种经典算法对比：BP（模糊）、FBP（滤波反投影）、SART/MLEM（迭代）

### 实践（先 MATLAB，后 Python）

- [x] `matlab/p01_shepp_logan_fbp.m` — 2D Shepp-Logan：BP vs FBP，输出图 + RMSE/SSIM
- [x] `matlab/p02_limited_angle_dbt.m` — 180° / 25° / 2.5° 有限角对照
- [ ] 阅读 `vendor/DBT-Reconstruction` 的 `FBP.m`、`SART.m`、`filterProj.m`
- [x] `matlab/p03_run_lavi_phantom.m` — 无 GUI 跑通工具箱 3D phantom FBP（quickMode 64³）
- [x] `matlab/p04_ct_dicom_fbp.m` — `data/OrigCTData` 真实轴位 CT 切片上复现 BP/FBP
- [x] `matlab/p05_ct_slice_viewer.m` — 体积工作站：加载 / 三平面 / 窗宽窗位 / 切片操作
- [x] `references/dbt-toolbox-notes.md` — 几何参数（DSD/DSO、探测器、角度步进）
- [ ] （随后）`notebooks/01_shepp_logan_fbp.ipynb` — 同一实验的 Python 对照

### 验收标准

- 能口头解释：为什么纯反投影会模糊？Ram-Lak 滤波起什么作用？
- 有一份 phantom FBP 重建图 + 与 ground truth 的定量对比

---

## Phase 2：真实 DBT 数据管线（第 5–8 周）

**目标：** 从 TCIA 真实 DICOM 到可评估的 3D 重建体积。

### 数据

- [ ] TCIA 注册并下载乳腺癌筛查 DBT 子集（先选 5–10 例调试）
- [ ] `src/io/dicom_reader.py` — 读取 DBT DICOM，提取投影栈与几何元数据
- [ ] 用 3D Slicer 目视检查原始体数据与投影方向

### 重建

- [ ] `src/reconstruction/back_projection.py` — 3D BP 基线
- [ ] `src/reconstruction/fbp.py` — 3D FBP（或 slice-wise FBP 作为中间步）
- [ ] 配置采集几何参数（参考 DICOM tag 或工具箱 `ParameterSettings`）
- [ ] 与厂商/工具箱重建结果做视觉 + 指标对比

### 验收标准

- 端到端脚本：`scripts/run_reconstruction.py --input data/raw/... --method fbp`
- 重建切片可视化 + 简短技术笔记

---

## Phase 3：前沿扩展（第 9 周起，可选）

**目标：** 理解「2D → 3D」在深度学习与可微渲染中的现代做法。

### DiffDRR（正向：3D → 2D）

- [ ] 安装 DiffDRR，用公开 CT 体积生成 DRR
- [ ] 理解 Siddon 射线追踪与 PyTorch autograd 的结合
- [ ] 尝试 [reconstruction tutorial](https://vivekg.dev/DiffDRR/tutorials/reconstruction.html) 的可微体积优化

### RadSurf（逆向：2D → 3D 表面）

- [ ] 阅读 RadSurf 论文与 [数据集说明](https://github.com/IGRS-medical-imaging/RadSurf)
- [ ] 对比：传统 FBP 体重建 vs 单视图 DL 表面重建的适用场景
- [ ] 思考：DR Tomo 背景下哪些思路可迁移到乳腺断层合成

### 与 flagship 项目衔接

- [ ] 将 Phase 1–2 代码整理为可开源的「DBT/投影重建工具箱」雏形
- [ ] 对齐 [双主线战略](../职业发展方向分析/双主线战略-三维重建×AI智能化.md) Phase 2–3 的 flagship 规划

---

## 每周时间分配建议

| 活动 | 时长 |
|------|------|
| 理论学习（书籍/论文） | 2–3 h |
| 代码实践（notebook / src） | 4–5 h |
| 阅读开源工具箱源码 | 1–2 h |
| 笔记整理（references/） | 1 h |
