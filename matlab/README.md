# MATLAB CT 三维可视化第一步

这个目录包含一套最小可运行的 MATLAB 流程，用于从 `E:\SelfProject\CTData\LungCT-Diagnosis` 读取 DICOM CT 数据，完成：

- 自动扫描并按 `SeriesInstanceUID` 分组 CT DICOM 序列
- 按切片方向和空间位置重排 3D 体数据
- 使用 HU 窗宽窗位展示 Axial / Coronal / Sagittal 三个平面
- 生成 body / bone / lung / soft 多种 3D 渲染预览

## 运行方式

1. 打开 MATLAB
2. 进入该目录：

```matlab
cd('E:\SelfProject\CT3D\matlab')
```

3. 运行主脚本：

```matlab
ct_pipeline_demo('E:\SelfProject\CTData\LungCT-Diagnosis')
```

或者直接使用默认路径：

```matlab
ct_pipeline_demo
```

默认会生成所有 3D 模式。也可以只生成某一种模式：

```matlab
ct_pipeline_demo('E:\SelfProject\CTData\LungCT-Diagnosis', 'body')
ct_pipeline_demo('E:\SelfProject\CTData\LungCT-Diagnosis', 'bone')
ct_pipeline_demo('E:\SelfProject\CTData\LungCT-Diagnosis', 'lung')
ct_pipeline_demo('E:\SelfProject\CTData\LungCT-Diagnosis', 'soft')
```

## 脚本说明

- `ct_pipeline_demo.m`：主入口，负责扫描 DICOM、按序列加载体数据、可视化和保存结果
- 输出图像将保存在 `matlab/output/` 目录中

## 预期输出

- `ct_overview.png`：CT 三视图 + 切片蒙太奇
- `ct_3d_body.png`：人体外轮廓 3D 表面渲染
- `ct_3d_bone.png`：骨骼高 HU 3D 表面渲染
- `ct_3d_lung.png`：肺部低 HU 3D 表面渲染
- `ct_3d_soft.png`：软组织 3D 表面渲染
- `ct_3d_view.png`：兼容旧文件名，内容同 `ct_3d_body.png`

## 下一步

本脚本是第一阶段的基础：

- 以后可扩展为窗口/阈值优化
- 再加入肺结节/病灶分割
- 最后过渡到重建/可视化流程
