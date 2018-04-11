CURVE TRACING FMRI EXPERIMENT CODE
====================================================

Runs in ptb3-based Tracker.
Main components:
    - runstim.m 
    The main driver. Determines experiment flow. References specific tasks for specific moment in the experiment flow.
    Which tasks is defined in the StimSettings, while their characteristic are in @objectfolders 
    
    - StimSettings.m
    Has all information about Stimuli. References csv-files with specifications and @objectfolders.

    - ParSettings.m
    Has the main information about reward and site-specific hardware parameters.

General flow of runstim.m
# Initialisation
# Pre-trigger task
    KeepSubjectBusyTask_PreScan or KeepSubjectBusyTask
        exits on real or simulated MRI trigger
# Main loop











=== Different tasks ===
KeepSubjectBusyTask_PreScan
KeepSubjectBusyTask