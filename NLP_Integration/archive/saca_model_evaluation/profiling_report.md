# Latency & Resource Profiling Report

- Profiling runs per model: `120`
- Single patient symptom count: `2`
- Winner (faster/lighter inference): `CatBoost`

| Model | Mean ms | P95 ms | Min ms | Max ms | Peak RAM MB | Setup Time s |
| --- | --- | --- | --- | --- | --- | --- |
| ExtraNGvboost | 56.306 | 68.179 | 44.850 | 104.669 | 458.660 | 0.469 |
| CatBoost | 6.265 | 7.744 | 5.126 | 10.331 | 535.898 | 14.076 |

Setup time is separated from per-patient inference time; production should preload models at service startup.
