# Mermaid Style Guide

- Always include an init block enabling HTML labels and consistent curves.
- Use provider subgraphs and classDefs for brand colors.
- Embed icons from `docs/assets/icons/...` with `<img ...>` in labels.
- Prefer LR for architecture; TD for flows; sequence diagrams for processes.
- Target ≤12 nodes per diagram unless showing the whole picture.

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
flowchart LR
  classDef aws fill:#F7F7F7,stroke:#FF9900,stroke-width:2px
  classDef k8s fill:#F7F7F7,stroke:#326CE5,stroke-width:2px
  subgraph AWS
    s3["<img src='../assets/icons/aws/s3.svg' width='18'/> S3"]
  end
  class AWS aws
  app["<img src='../assets/icons/k8s/k8s.svg' width='18'/> BTP"]
  class app k8s
  app --> s3
```

