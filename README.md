# Scientific Research: The Trade Consequences of Sanctions.   

This repository contains the code used to replicate the quantitative analysis of an international economics research project on economic sanctions and international trade.

---
## Overview

The project consists of two main empirical sections:

### Sections 1: TRADE UNDER PRESSURE: A QUASI-EXPERIMENTAL DESIGN ON SANCTIONS
A quasi-experimental study on the causal effects of sanctions on trade flows, implemented within a staggered Difference-in-Differences framework. The analysis employs:
- Two-Way Fixed Effects. 
- Extended Two-Way Fixed Effects.
- Callaway & Sant'Anna (2021) estimator.

### Section 2: WHEN SANCTIONS STRIKE: DO THEY DISRUPT TRADE–COMOVEMENT?
A quantitative analysis of the role of sanctions in moderating the relationship between trade intensity and business cycle comovement. The empirical strategy includes:
- Method of Moments Quantile Regression.
- Complete Subset Averaging Two-Stage Least Squares. 

---
## Requirements

- Stata 17 or above.
- Required user-written packages:
  - `jwdid` (latest version).

Please ensure that the latest versions of `jwdid.ado` and `jwdid_estat.ado` are installed by overwriting existing versions:
https://github.com/friosavila/stpackages/tree/main/jwdid.

---
## Data
The datasets are not included in this repository.

### Data sources
- Global Sacntions Database (GSDB).
- Research and Expertise on the World Economy (CEPII).

### Access
The data can be downloaded from:
https://drive.google.com/drive/folders/13DpGKoT70Z6LVx6NmO6TrKQrLojECB6O?usp=sharing.

---
## How to Run the Replication

1. Set the working directory in Stata:
- Open each code file and modify the global paths to match your local directory structure.

2. Run the data processing pipeline:
- Open `01_data_processing.do`.
- This script will:
  - Process raw GSDB and CEPII data.
  - Merge datasets.
  - Construct datasets for the empirical analysis.
  - Generate two main datasets:
    - `data_sdid.dta`: dataset used for the quasi-experimental analysis in Section 1.
    - `data_tradecomov.dta`: dataset used for the empirical analysis in Section 2.

3. Run the empirical analysis:
  - For Section 1: `03_regression_chapter3.do`.
  - For Section 2: `04_regression_chapter4.do`.

4. Generate figures:
- For Section 1: Figures are generated using `02_data_graph.do`.
- For Section 2: Figures is produced within `04_regression_chapter4.do`.

## Notes

- The replication results may vary depending on system settings and package versions.

## Contributors

- M.A. Trinh Minh Quy.
- Dang Minh Nhat.
- Nguyen Trung Hieu.

## Affiliation
University of Economics and Law, Vietnam National University, Ho Chi Minh City.

## Contact

For questions or replication issues, please contact:  
- nhatdang0164@gmail.com
- minhquy0710@gmail.com
- hieunt23408a@st.uel.edu.vn
