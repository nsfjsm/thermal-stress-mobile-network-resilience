# Thermal Stress and Mobile Network Resilience

This repository contains the Python and MATLAB code associated with the research paper:

**Thermal Stress and Mobile Network Resilience: A Comparative Analysis of Iraq and Kuwait**

## Authors

- Hasanain A.H. Al-Behadili
- Nasif Jasim Hadi
- Maab Alaa Isamail
- Sarah Kareem Salim

## Description

The repository provides the code used to generate the figures and reproduce the numerical trends reported in the manuscript.

The study investigates the effect of extreme ambient temperatures on mobile network performance in Iraq and Kuwait.

The analysed network performance indicators include:

- Reference Signal Received Power (RSRP)
- Signal-to-Interference-plus-Noise Ratio (SINR)
- Packet loss rate
- Downlink throughput
- Base station failure rate
- Handover success rate
- Environmental and network KPI correlations
- Mitigation impact

## Repository Contents

- `Getfig.py`: Python implementation used to generate the figures.
- `GetHeatFigures.m`: MATLAB implementation used to generate the figures.
- `requirements.txt`: Required Python packages.
- `figures/`: Generated figures in PNG and PDF formats.

## Python Requirements

The Python implementation requires:

- NumPy
- Pandas
- Matplotlib
- Seaborn
- SciPy

Install the required packages using:

```bash
pip install -r requirements.txt
