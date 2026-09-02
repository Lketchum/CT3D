# 学习路径与里程碑

## Phase 1：原理打底 + Phantom 实验（第 1–4 周）

**目标：** 亲手跑通「投影 → 反投影 → 3D 体」，建立与 CT 重建一致的心智模型。

### 理论

- [ ] Radon 变换与 FBP 公式推导（参考《Computed Tomography Principles...》）
- [ ] DBT 与 CT 的几何差异：有限角度、半锥束、圆形/非圆形轨迹
- [ ] 三种经典算法对比：BP（模糊）、FBP（滤波反投影）、SART/MLEM（迭代）

### 实践

- [ ] `notebooks/01_shepp_logan_fbp.ipynb` — Python 2D FBP on Shepp-Logan phantom
- [ ] 克隆 [DBT-Reconstruction](https://github.com/LAVI-USP/DBT-Reconstruction)，运行内置 phantom 示例
- [ ] 对照 MATLAB 与 Python 输出，记录 SSIM / RMSE 差异
- [ ] `references/dbt-toolbox-notes.md` — 记录几何参数（SDD、探测器尺寸、角度步进）如何影响重建

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
