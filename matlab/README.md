# MATLAB — 两条线

| 线 | 做什么 | 入口 |
|----|--------|------|
| **工作站（你现在要的）** | 加载 CT 体积、三平面显示、对切片做窗宽/翻层/层厚/导出 | `p05_ct_slice_viewer`（必须在 MATLAB 桌面打开） |
| **重建算法（p01–p04）** | 投影物理：Radon / BP / FBP，从信号模型恢复图像 | `p01` … `p04` |

p01–p04 **不是** ADC（物理信号→数字采样）。那是「已有投影或已有体积之后，用滤波反投影再算一遍」。厂商重建机已经把 DICOM 做成体积了；工作站工程师的日常是加载、显示、质控切片。

## 体积工作站

在 MATLAB 命令行（不要用 `-batch`）：

```matlab
cd('d:/AI_assist_project/CT3D/matlab')
p05_ct_slice_viewer
```

扫描仪已经把 DICOM 建成三维体积。本工具把切片堆成 512×512×N 的体，然后：

- **轴位下方进度条**：拖动即换 DICOM 层（例如 1/130 … 130/130），右侧数字框可直接跳层
- **冠状 / 矢状进度条**：换另外两个方向的位置
- **右侧 3D**：骨骼表面 / 体表 / 体绘制 / MIP，鼠标旋转
- 顶部 Window 只调窗宽窗位（亮度对比），**不换层**

- 下拉框切换 `OrigCTData` 里的轴位序列，点 **Load**
- 点某个视图后，滚轮或方向键也可翻层；点击移动十字线
- **Slab + mean/MIP**：加厚显示

## 重建算法实验

按顺序运行（在 MATLAB 里打开脚本，或用命令行）：

```matlab
cd('d:/AI_assist_project/CT3D/matlab')
p01_shepp_logan_fbp      % 2D Shepp-Logan：BP vs FBP
p02_limited_angle_dbt    % 全角度 CT vs 有限角度 DBT
p03_run_lavi_phantom     % LAVI 工具箱 3D phantom（无 GUI）
p04_ct_dicom_fbp         % 读取 data/OrigCTData 轴位 CT，同一套 BP/FBP
p06_read_single_dicom    % 读一张 DICOM：像素图 + 关键 tag
```

命令行：

```powershell
matlab -batch "cd('d:/AI_assist_project/CT3D/matlab'); p01_shepp_logan_fbp"
```

结果写到 `data/processed/phase1/`（图 + `.mat` 指标）。

| 脚本 | 作用 | 依赖 |
|------|------|------|
| `p01_shepp_logan_fbp.m` | 全角度 2D FBP，对照 Ram-Lak | IPT (`phantom`/`radon`/`iradon`) |
| `p02_limited_angle_dbt.m` | 180° / 25° / 2.5° 三种覆盖 | 同上 |
| `p03_run_lavi_phantom.m` | 调用 `vendor/DBT-Reconstruction` 的 `projection` + `FBP` | 先克隆工具箱 |
| `p04_ct_dicom_fbp.m` | 加载 `data/OrigCTData` 轴位 CT，切片上复现 p01/p02 | IPT (`dicomreadVolume`) |

`p04` 的数据是**已经重建好的 CT 体积**，不是 DBT 投影。脚本会：读 DICOM → 取中间层当 GT → Radon 模拟投影 → BP/FBP/有限角。不要把这些文件丢给工具箱 `Reconstruction.m` 的 Clinical 模式。

换序列：改 `p04_ct_dicom_fbp.m` 顶部的 `seriesDir`。默认用胸部 `AXIAL ST 3.0 X 3.0`（130 层）。

`03` 默认 `quickMode=true`（64³），首次跑通后再改 `false` 用工具箱原版 128³。

工具箱本体带 GUI（`Reconstruction.m`）。日常对照用 `03`，读源码用：

- `vendor/DBT-Reconstruction/FBP.m`
- `vendor/DBT-Reconstruction/SART.m`
- `vendor/DBT-Reconstruction/Parameters/ParameterSettings_Phantom.m`
