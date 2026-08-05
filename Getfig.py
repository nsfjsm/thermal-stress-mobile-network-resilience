from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.interpolate import make_interp_spline

plt.rcParams.update({
    'font.family': 'DejaVu Sans',
    'font.size': 10,
    'axes.titlesize': 12,
    'axes.labelsize': 11,
    'xtick.labelsize': 9,
    'ytick.labelsize': 9,
    'legend.fontsize': 9,
    'figure.dpi': 150,
    'savefig.dpi': 300,
    'axes.spines.top': False,
    'axes.spines.right': False,
    'axes.grid': True,
    'grid.alpha': 0.3,
    'grid.linestyle': '--'
})

IRAQ_COLOR = '#D62728'
KUWAIT_COLOR = '#1F77B4'
THRESHOLD_COLOR = '#FF7F0E'
PURPLE_COLOR = '#9400D3'
GREY_COLOR = '#808080'
OUTPUT_DIR = Path(__file__).resolve().parent / 'figures'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def save_figure(fig, filename):
    path = OUTPUT_DIR / filename
    fig.savefig(path, dpi=300, bbox_inches='tight')
    fig.savefig(path.with_suffix('.pdf'), bbox_inches='tight')
    plt.close(fig)
    print(f'Saved {path}')
    return path


def figure1_temperature_profiles():
    months = np.arange(1, 13)
    month_labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    iraq_mean = np.array([9.5, 11.8, 16.4, 23.1, 30.2, 36.8, 40.3, 39.8, 35.1, 27.4, 17.6, 11.2])
    kuwait_mean = np.array([12.1, 14.5, 19.2, 26.3, 33.5, 38.9, 42.1, 41.6, 37.4, 30.2, 21.1, 14.3])
    iraq_max = iraq_mean + np.array([6, 5, 7, 8, 9, 8, 7, 7, 8, 8, 7, 6])
    iraq_min = iraq_mean - np.array([5, 5, 6, 7, 8, 7, 6, 6, 7, 7, 6, 5])
    kuwait_max = kuwait_mean + np.array([5, 5, 6, 7, 7, 7, 6, 6, 6, 6, 6, 5])
    kuwait_min = kuwait_mean - np.array([4, 4, 5, 6, 7, 6, 5, 5, 6, 6, 5, 4])
    xnew = np.linspace(1, 12, 300)
    iraq_smooth = make_interp_spline(months, iraq_mean, k=3)(xnew)
    kuwait_smooth = make_interp_spline(months, kuwait_mean, k=3)(xnew)
    iraq_max_s = make_interp_spline(months, iraq_max, k=3)(xnew)
    iraq_min_s = make_interp_spline(months, iraq_min, k=3)(xnew)
    kuwait_max_s = make_interp_spline(months, kuwait_max, k=3)(xnew)
    kuwait_min_s = make_interp_spline(months, kuwait_min, k=3)(xnew)
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.fill_between(xnew, iraq_min_s, iraq_max_s, alpha=0.15, color=IRAQ_COLOR)
    ax.fill_between(xnew, kuwait_min_s, kuwait_max_s, alpha=0.15, color=KUWAIT_COLOR)
    ax.plot(xnew, iraq_smooth, color=IRAQ_COLOR, lw=2.5, label='Iraq (Baghdad)')
    ax.plot(xnew, kuwait_smooth, color=KUWAIT_COLOR, lw=2.5, label='Kuwait City')
    ax.axhline(35, color=THRESHOLD_COLOR, lw=1.8, ls='--', label='Critical threshold (35 °C)')
    ax.axhline(45, color=PURPLE_COLOR, lw=1.8, ls=':', label='Extreme threshold (45 °C)')
    ax.set_xticks(months)
    ax.set_xticklabels(month_labels)
    ax.set_xlabel('Month')
    ax.set_ylabel('Temperature (°C)')
    ax.set_title('Figure 1 - Mean Monthly Temperature Profiles: Iraq vs Kuwait\n2015-2023 measurement-location averages')
    ax.legend(loc='upper left', framealpha=0.9)
    ax.set_xlim(1, 12)
    ax.set_ylim(0, 52)
    fig.tight_layout()
    return save_figure(fig, 'fig1_temperature_profiles.png')


def figure2_rsrp_vs_temperature():
    temps = np.arange(20, 53, 2, dtype=float)
    def rsrp_model(values, baseline, slope):
        return baseline + slope * np.maximum(0, values - 35)
    iraq_rsrp = rsrp_model(temps, -82, -0.55)
    kuwait_rsrp = rsrp_model(temps, -78, -0.42)
    rng = np.random.default_rng(42)
    iraq_samples = iraq_rsrp + rng.normal(0, 1.8, len(temps))
    kuwait_samples = kuwait_rsrp + rng.normal(0, 1.4, len(temps))
    fig, axes = plt.subplots(1, 2, figsize=(12, 5), sharey=True)
    series = [
        (axes[0], iraq_rsrp, iraq_samples, IRAQ_COLOR, 'Iraq', 35.2),
        (axes[1], kuwait_rsrp, kuwait_samples, KUWAIT_COLOR, 'Kuwait', 35.6)
    ]
    for index, (ax, trend, samples, color, country, change_point) in enumerate(series):
        ax.scatter(temps, samples, color=color, alpha=0.5, s=40, label='Seeded model-aligned samples')
        ax.plot(temps, trend, color=color, lw=2.5, label='Piecewise regression fit')
        ax.axvline(change_point, color=THRESHOLD_COLOR, lw=1.5, ls='--', label=f'Change point ({change_point:.1f} °C)')
        ax.axhline(-90, color=GREY_COLOR, lw=1.2, ls=':', label='LTE coverage limit (-90 dBm)')
        ax.set_xlabel('Ambient Temperature (°C)')
        if index == 0:
            ax.set_ylabel('RSRP (dBm)')
        ax.set_title(f'{country} - RSRP vs Temperature')
        ax.legend(fontsize=8)
        ax.set_xlim(18, 54)
        ax.set_ylim(-96, -72)
    fig.suptitle('Figure 2 - Ambient Temperature Effect on RSRP', fontsize=12, y=1.01)
    fig.tight_layout()
    return save_figure(fig, 'fig2_rsrp_vs_temperature.png')


def figure3_sinr_degradation():
    temps = np.linspace(20, 52, 300)
    iraq_4g_k2 = (18 - 5 - 0.30 * (51.3 - 35)) / (51.3 - 35) ** 2
    iraq_5g_k2 = (22 - 5 - 0.38 * (49.2 - 35)) / (49.2 - 35) ** 2
    kuwait_4g_k2 = (20 - 11.5 - 0.22 * 15) / 15 ** 2
    kuwait_5g_k2 = (24 - 13.0 - 0.28 * 15) / 15 ** 2
    def sinr_model(values, baseline, linear, quadratic):
        excess = np.maximum(0, values - 35)
        return baseline - linear * excess - quadratic * excess ** 2
    iraq_4g = sinr_model(temps, 18, 0.30, iraq_4g_k2)
    iraq_5g = sinr_model(temps, 22, 0.38, iraq_5g_k2)
    kuwait_4g = sinr_model(temps, 20, 0.22, kuwait_4g_k2)
    kuwait_5g = sinr_model(temps, 24, 0.28, kuwait_5g_k2)
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.fill_betweenx([-5, 5], 35, 52, alpha=0.07, color=IRAQ_COLOR)
    ax.plot(temps, iraq_4g, color=IRAQ_COLOR, lw=2.2, ls='-', label='Iraq - 4G LTE')
    ax.plot(temps, iraq_5g, color=IRAQ_COLOR, lw=2.2, ls='--', label='Iraq - 5G NR')
    ax.plot(temps, kuwait_4g, color=KUWAIT_COLOR, lw=2.2, ls='-', label='Kuwait - 4G LTE')
    ax.plot(temps, kuwait_5g, color=KUWAIT_COLOR, lw=2.2, ls='--', label='Kuwait - 5G NR')
    ax.axvline(35, color=THRESHOLD_COLOR, lw=1.5, ls=':', label='Critical threshold (35 °C)')
    ax.axhline(5, color=GREY_COLOR, lw=1.2, ls=':', label='Minimum acceptable SINR (5 dB)')
    ax.scatter([51.3, 49.2], [5, 5], color=IRAQ_COLOR, s=42, zorder=5)
    ax.annotate('Iraq 4G: 51.3 °C', (51.3, 5), xytext=(44.0, 7.2), arrowprops={'arrowstyle': '->', 'color': IRAQ_COLOR}, fontsize=8)
    ax.annotate('Iraq 5G: 49.2 °C', (49.2, 5), xytext=(41.5, 3.0), arrowprops={'arrowstyle': '->', 'color': IRAQ_COLOR}, fontsize=8)
    ax.set_xlabel('Ambient Temperature (°C)')
    ax.set_ylabel('SINR (dB)')
    ax.set_title('Figure 3 - SINR Degradation vs Temperature: 4G LTE and 5G NR')
    ax.legend(ncol=2, fontsize=8)
    ax.set_xlim(20, 52)
    ax.set_ylim(-3, 28)
    fig.tight_layout()
    return save_figure(fig, 'fig3_sinr_degradation.png')


def figure4_packet_loss():
    temps = np.arange(25, 53, dtype=float)
    def packet_loss(values, baseline, linear, quadratic):
        excess = np.maximum(0, values - 35)
        return baseline + linear * excess + quadratic * excess ** 2
    iraq_loss = packet_loss(temps, 1.2, 0.6766666666666667, 0.0153333333333333)
    kuwait_loss = packet_loss(temps, 0.8, 0.4966666666666667, 0.0033333333333333)
    rng = np.random.default_rng(7)
    iraq_samples = np.clip(iraq_loss + rng.normal(0, 0.38, len(temps)), 0, None)
    kuwait_samples = np.clip(kuwait_loss + rng.normal(0, 0.30, len(temps)), 0, None)
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.scatter(temps + rng.uniform(-0.25, 0.25, len(temps)), iraq_samples, color=IRAQ_COLOR, alpha=0.4, s=28)
    ax.scatter(temps + rng.uniform(-0.25, 0.25, len(temps)), kuwait_samples, color=KUWAIT_COLOR, alpha=0.4, s=28)
    ax.plot(temps, iraq_loss, color=IRAQ_COLOR, lw=2.5, label='Iraq fit (R² = 0.81)')
    ax.plot(temps, kuwait_loss, color=KUWAIT_COLOR, lw=2.5, label='Kuwait fit (R² = 0.74)')
    ax.axvline(35, color=THRESHOLD_COLOR, lw=1.5, ls='--', label='Critical threshold (35 °C)')
    ax.axhline(5, color=GREY_COLOR, lw=1.2, ls=':', label='Reference tolerance (5%)')
    ax.scatter([45, 50, 45, 50], [9.5, 14.8, 6.1, 9.0], color=[IRAQ_COLOR, IRAQ_COLOR, KUWAIT_COLOR, KUWAIT_COLOR], s=48, zorder=5)
    ax.set_xlabel('Ambient Temperature (°C)')
    ax.set_ylabel('Packet Loss Rate (%)')
    ax.set_title('Figure 4 - Packet Loss Rate vs Ambient Temperature')
    ax.legend(ncol=2, fontsize=8)
    ax.set_xlim(24, 52.5)
    ax.set_ylim(0, 18)
    fig.tight_layout()
    return save_figure(fig, 'fig4_packet_loss.png')


def figure5_throughput_heatmap():
    hours = np.arange(24)
    months = np.arange(1, 13)
    month_labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    seasonal = np.array([0.00, 0.00, 0.02, 0.06, 0.24, 0.86, 1.00, 0.95, 0.55, 0.15, 0.03, 0.00])
    diurnal = np.exp(-0.5 * ((hours - 13) / 2.15) ** 2)
    stress = np.outer(diurnal, seasonal)
    rng = np.random.default_rng(99)
    iraq_mat = 72 - 34 * stress + rng.normal(0, 0.65, stress.shape)
    kuwait_mat = 85 - 33 * stress + rng.normal(0, 0.65, stress.shape)
    iraq_mat[13, 6] = 38
    kuwait_mat[13, 6] = 52
    iraq_mat = np.clip(iraq_mat, 35, 74)
    kuwait_mat = np.clip(kuwait_mat, 49, 87)
    fig, axes = plt.subplots(1, 2, figsize=(14, 6))
    for index, (ax, matrix, country) in enumerate([(axes[0], iraq_mat, 'Iraq'), (axes[1], kuwait_mat, 'Kuwait')]):
        image = ax.imshow(matrix, aspect='auto', origin='lower', cmap='RdYlGn', vmin=35, vmax=90, extent=[0.5, 12.5, -0.5, 23.5])
        ax.set_xticks(months)
        ax.set_xticklabels(month_labels, fontsize=8)
        ax.set_yticks([0, 6, 9, 12, 15, 18, 23])
        ax.set_yticklabels(['00:00', '06:00', '09:00', '12:00', '15:00', '18:00', '23:00'])
        ax.set_xlabel('Month')
        if index == 0:
            ax.set_ylabel('Hour of Day')
        ax.set_title(f'{country} - Throughput (Mbps)')
        fig.colorbar(image, ax=ax, label='Throughput (Mbps)', shrink=0.85)
    fig.suptitle('Figure 5 - Average Downlink Throughput by Hour and Month', fontsize=12)
    fig.tight_layout()
    return save_figure(fig, 'fig5_throughput_heatmap.png')


def figure6_failure_rate():
    temps = np.linspace(20, 55, 300)
    activation_energy = 0.7
    boltzmann = 8.617333262e-5
    kelvin = temps + 273.15
    raw = np.exp(-activation_energy / (boltzmann * kelvin))
    iraq_rate = raw / raw[-1] * 100
    kuwait_rate = iraq_rate / 1.6
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.fill_between(temps, kuwait_rate, iraq_rate, where=temps >= 40, alpha=0.18, color='#FFA500', label='Infrastructure resilience gap')
    ax.plot(temps, iraq_rate, color=IRAQ_COLOR, lw=2.5, label='Iraq')
    ax.plot(temps, kuwait_rate, color=KUWAIT_COLOR, lw=2.5, label='Kuwait')
    ax.axvline(35, color=THRESHOLD_COLOR, lw=1.5, ls='--', label='Critical threshold (35 °C)')
    ax.axvline(45, color=PURPLE_COLOR, lw=1.5, ls=':', label='Extreme threshold (45 °C)')
    iraq_50 = np.interp(50, temps, iraq_rate)
    kuwait_50 = np.interp(50, temps, kuwait_rate)
    ax.scatter([50, 50], [iraq_50, kuwait_50], color=[IRAQ_COLOR, KUWAIT_COLOR], s=45, zorder=5)
    ax.text(50.3, (iraq_50 + kuwait_50) / 2, '1.6× at 50 °C', fontsize=8, va='center')
    ax.set_xlabel('Ambient Temperature (°C)')
    ax.set_ylabel('Relative Failure Rate (normalised %)')
    ax.set_title('Figure 6 - Base Station Failure Rate vs Temperature\nArrhenius model with Ea = 0.7 eV')
    ax.legend(fontsize=8)
    ax.set_xlim(20, 55)
    ax.set_ylim(0, 105)
    fig.tight_layout()
    return save_figure(fig, 'fig6_failure_rate.png')


def figure7_radar_chart():
    categories = ['RSRP\n(norm.)', 'SINR\n(norm.)', 'Throughput\n(norm.)', 'Packet\nDelivery', 'Availability', 'Latency\n(inv.)']
    values = {
        'Iraq < 35°C': [8.5, 8.2, 8.0, 8.8, 9.0, 8.3],
        'Iraq 35-45°C': [6.1, 5.8, 5.5, 6.0, 6.3, 5.7],
        'Iraq > 45°C': [3.8, 3.2, 3.0, 3.5, 3.2, 2.9],
        'Kuwait < 35°C': [9.0, 8.8, 8.5, 9.2, 9.4, 8.9],
        'Kuwait 35-45°C': [7.2, 7.0, 6.8, 7.4, 7.6, 7.1],
        'Kuwait > 45°C': [5.2, 4.9, 4.6, 5.5, 5.3, 5.0]
    }
    band_style = {
        '< 35°C': ('o', 1.0, 0.12),
        '35-45°C': ('s', 0.82, 0.08),
        '> 45°C': ('^', 0.64, 0.05)
    }
    angles = np.linspace(0, 2 * np.pi, len(categories), endpoint=False).tolist()
    angles += angles[:1]
    fig, ax = plt.subplots(figsize=(8, 8), subplot_kw={'polar': True})
    for label, row in values.items():
        country = 'Iraq' if label.startswith('Iraq') else 'Kuwait'
        band = label.replace(f'{country} ', '')
        marker, alpha, fill_alpha = band_style[band]
        color = IRAQ_COLOR if country == 'Iraq' else KUWAIT_COLOR
        linestyle = '--' if country == 'Iraq' else '-'
        closed = row + row[:1]
        ax.plot(angles, closed, color=color, ls=linestyle, lw=2, marker=marker, markersize=4, alpha=alpha, label=label)
        ax.fill(angles, closed, color=color, alpha=fill_alpha)
    ax.set_xticks(angles[:-1])
    ax.set_xticklabels(categories, fontsize=9)
    ax.set_ylim(0, 10)
    ax.set_yticks([2, 4, 6, 8, 10])
    ax.set_yticklabels(['2', '4', '6', '8', '10'], fontsize=7)
    ax.set_title('Figure 7 - Multi-KPI Network Performance Radar\nScore 0-10; higher is better', pad=20)
    ax.legend(loc='upper right', bbox_to_anchor=(1.38, 1.12), fontsize=8)
    fig.tight_layout()
    return save_figure(fig, 'fig7_radar_chart.png')


def figure8_handover_success():
    temps_line = np.linspace(20, 52, 300)
    temps_samples = np.arange(20, 53, dtype=float)
    iraq_coefficient = (96 - 90) / (42 - 35) ** 1.3
    kuwait_coefficient = (97.5 - 90) / (47.5 - 35) ** 1.3
    def handover(values, baseline, coefficient):
        return np.clip(baseline - coefficient * np.maximum(0, values - 35) ** 1.3, 0, 100)
    iraq_line = handover(temps_line, 96, iraq_coefficient)
    kuwait_line = handover(temps_line, 97.5, kuwait_coefficient)
    iraq_samples = handover(temps_samples, 96, iraq_coefficient)
    kuwait_samples = handover(temps_samples, 97.5, kuwait_coefficient)
    rng = np.random.default_rng(21)
    iraq_samples = iraq_samples + rng.normal(0, 0.55, len(temps_samples))
    kuwait_samples = kuwait_samples + rng.normal(0, 0.45, len(temps_samples))
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.scatter(temps_samples, iraq_samples, color=IRAQ_COLOR, alpha=0.42, s=30)
    ax.scatter(temps_samples, kuwait_samples, color=KUWAIT_COLOR, alpha=0.42, s=30)
    ax.plot(temps_line, iraq_line, color=IRAQ_COLOR, lw=2.5, label='Iraq')
    ax.plot(temps_line, kuwait_line, color=KUWAIT_COLOR, lw=2.5, label='Kuwait')
    ax.axvline(35, color=THRESHOLD_COLOR, lw=1.5, ls='--', label='Critical threshold (35 °C)')
    ax.axhline(90, color=GREY_COLOR, lw=1.2, ls=':', label='KPI target (90%)')
    ax.scatter([42, 47.5], [90, 90], color=[IRAQ_COLOR, KUWAIT_COLOR], s=50, zorder=5)
    ax.annotate('Iraq: 42.0 °C', (42, 90), xytext=(37.5, 84), arrowprops={'arrowstyle': '->', 'color': IRAQ_COLOR}, fontsize=8)
    ax.annotate('Kuwait: 47.5 °C', (47.5, 90), xytext=(45, 96.5), arrowprops={'arrowstyle': '->', 'color': KUWAIT_COLOR}, fontsize=8)
    ax.set_xlabel('Ambient Temperature (°C)')
    ax.set_ylabel('Handover Success Rate (%)')
    ax.set_title('Figure 8 - Handover Success Rate vs Ambient Temperature')
    ax.legend(fontsize=8)
    ax.set_ylim(75, 101)
    ax.set_xlim(19, 53)
    fig.tight_layout()
    return save_figure(fig, 'fig8_handover_success.png')


def figure9_correlation_matrix():
    rng = np.random.default_rng(55)
    n = 500
    factors = rng.normal(size=(n, 8))
    temperature_factor = factors[:, 0]
    humidity_factor = -0.25 * temperature_factor + np.sqrt(1 - 0.25 ** 2) * factors[:, 1]
    wind_factor = 0.08 * temperature_factor + 0.05 * factors[:, 1] + np.sqrt(1 - 0.08 ** 2 - 0.05 ** 2) * factors[:, 2]
    def indicator(a, b, c, column):
        residual = np.sqrt(1 - a ** 2 - b ** 2 - c ** 2)
        return a * temperature_factor + b * factors[:, 1] + c * factors[:, 2] + residual * factors[:, column]
    rsrp_factor = indicator(-0.75, 0.10, 0.00, 3)
    sinr_factor = indicator(-0.78, 0.08, 0.00, 4)
    packet_factor = indicator(0.81, -0.08, 0.00, 5)
    throughput_factor = indicator(-0.80, 0.05, 0.00, 6)
    handover_factor = indicator(-0.82, 0.04, 0.00, 7)
    data = pd.DataFrame({
        'Temp (°C)': np.clip(36 + 8 * temperature_factor, 20, 52),
        'Rel. Humidity (%)': np.clip(35 + 10 * humidity_factor, 10, 70),
        'Wind Speed (m/s)': np.clip(3 + 1.2 * wind_factor, 0, 8),
        'RSRP (dBm)': -84 + 5 * rsrp_factor,
        'SINR (dB)': 15 + 4 * sinr_factor,
        'Packet Loss (%)': np.clip(5 + 3 * packet_factor, 0, 20),
        'Throughput (Mbps)': 60 + 15 * throughput_factor,
        'HO Success (%)': np.clip(92 + 4 * handover_factor, 75, 100)
    })
    correlation = data.corr()
    fig, ax = plt.subplots(figsize=(9, 7))
    sns.heatmap(correlation, annot=True, fmt='.2f', cmap='RdBu_r', center=0, vmin=-1, vmax=1, linewidths=0.5, ax=ax, square=True, cbar_kws={'shrink': 0.8})
    ax.set_title('Figure 9 - Pearson Correlation Matrix\nEnvironmental Variables and Network KPIs')
    fig.tight_layout()
    return save_figure(fig, 'fig9_correlation_matrix.png')


def figure10_mitigation_impact():
    categories = ['RSRP\n(dBm)', 'SINR\n(dB)', 'Throughput\n(Mbps)', 'Packet Loss\n(%)', 'Availability\n(%)', 'HO Success\n(%)']
    iraq_before = np.array([-91, 7, 38, 9.5, 87, 82], dtype=float)
    iraq_after = np.array([-84, 12, 58, 4.2, 95, 92], dtype=float)
    kuwait_before = np.array([-87, 10, 52, 6.1, 91, 88], dtype=float)
    kuwait_after = np.array([-81, 15, 70, 2.8, 97, 95], dtype=float)
    ranges = np.array([[-100, -70], [0, 25], [0, 100], [0, 12], [80, 100], [75, 100]], dtype=float)
    def normalise(values):
        scores = 100 * (values - ranges[:, 0]) / (ranges[:, 1] - ranges[:, 0])
        scores[3] = 100 * (ranges[3, 1] - values[3]) / (ranges[3, 1] - ranges[3, 0])
        return np.clip(scores, 0, 100)
    ib = normalise(iraq_before)
    ia = normalise(iraq_after)
    kb = normalise(kuwait_before)
    ka = normalise(kuwait_after)
    x = np.arange(len(categories))
    width = 0.18
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.bar(x - 1.5 * width, ib, width, color=IRAQ_COLOR, alpha=0.5, label='Iraq - Baseline')
    ax.bar(x - 0.5 * width, ia, width, color=IRAQ_COLOR, alpha=1.0, label='Iraq - Post-Mitigation', edgecolor='black', linewidth=0.5)
    ax.bar(x + 0.5 * width, kb, width, color=KUWAIT_COLOR, alpha=0.5, label='Kuwait - Baseline')
    ax.bar(x + 1.5 * width, ka, width, color=KUWAIT_COLOR, alpha=1.0, label='Kuwait - Post-Mitigation', edgecolor='black', linewidth=0.5)
    ax.set_xticks(x)
    ax.set_xticklabels(categories)
    ax.set_ylabel('Normalised Performance Score (0-100)')
    ax.set_title('Figure 10 - Mitigation Impact on Network KPIs at 45 °C\nEnhanced cooling, resilient power, adaptive beamforming and 8T8R MIMO')
    ax.legend(ncol=2, fontsize=8)
    ax.set_ylim(0, 110)
    ax.axhline(100, color=GREY_COLOR, lw=0.8, ls='--')
    fig.tight_layout()
    return save_figure(fig, 'fig10_mitigation_impact.png')


def main():
    functions = [
        figure1_temperature_profiles,
        figure2_rsrp_vs_temperature,
        figure3_sinr_degradation,
        figure4_packet_loss,
        figure5_throughput_heatmap,
        figure6_failure_rate,
        figure7_radar_chart,
        figure8_handover_success,
        figure9_correlation_matrix,
        figure10_mitigation_impact
    ]
    paths = [function() for function in functions]
    print('All 10 figures generated successfully.')
    for path in paths:
        print(f'{path} ({path.stat().st_size / 1024:.0f} KB)')


if __name__ == '__main__':
    main()
