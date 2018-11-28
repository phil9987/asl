import argparse
import os, re, glob, csv, pprint
import matplotlib
matplotlib.use('Agg') # So we can save the figures to .png files
import matplotlib.pyplot as plt
import numpy as np
import scipy as sp


def plot_generic(xs, ys, yerrs=None, labels='', fmt=".-", markersize=8, capsize=8,
         ymax=None, title='', xlabel='', ylabel='',
         xticks=None, yticks=None, save_file=None, size=None):
    '''
    xs          [x1,..,xn] or [[x1,..,xn],[x1,..,xn],...,[x1,..,xn]]
                    x-axis values. If multiple lines are plotted, should use identical values.
    ys          [y1,..,yn] or [[y11,..,y1n],[y21,..,y2n],...,[ym1,..,ymn]]
                    y-axis values. Possible to plot multiple lines on one plot.
    yerrs       Stdev for ys, same dim as ys. If None, will be ignored
    labels      Label of graphs, sring or list of strings
    fmt         Matplotlib line styles. Single style or list of styles
    markersize  Size of datapoints
    capsize     Size of horizontal bars of errorbars
    ymax        Y-axis max. Single integer.
    xlabel      X-axis label
    ylabel      Y-axis label
    xticks      Can be None
    yticks      Can be None
    save_file   String w/ png extension
    size        Size of figure. Affects resolution (?). Can be None.
    '''

    if not isinstance(xs[0], list):
        xs = [xs]
        ys = [ys]
        if yerrs is not None:
            yerrs = [yerrs]
        labels = [labels]
        fmt = [fmt]

    fig, ax = plt.subplots(figsize=size)
    
    # Plot with error bars
    if yerrs is not None:
        y_tmp = -1
        for (x, y, yerr, label, f) in zip(xs, ys, yerrs, labels, fmt):
            if yerr is not None:
                ax.errorbar(x, y, yerr=yerr, fmt=f, markersize=markersize, capsize=capsize, label=label)
            else:
                ax.plot(x, y, f, markersize=markersize, label=label)
            if ymax is None and y_tmp < max(y):
                y_tmp = max(y)
        if ymax is None:
            ymax = 1.1*y_tmp
        ax.set_ylim(ymin=0, ymax=ymax)
    else: # Plot without error bars
        y_tmp = -1
        for (x, y, label, f) in zip(xs, ys, labels, fmt):
            ax.plot(x, y, f, markersize=markersize, label=label)
            if ymax is None and y_tmp < max(y):
                y_tmp = max(y)
        if ymax is None:
            ymax = 1.1*y_tmp
        ax.set_ylim(ymin=0, ymax=ymax)
    
    legend = ax.legend(loc='best', shadow=False)
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    if xticks is not None:
        plt.xticks(xticks)
    if yticks is not None:
        plt.yticks(yticks)
    plt.savefig(save_file)
    plt.clf()