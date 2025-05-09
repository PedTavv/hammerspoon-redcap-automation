# Hammerspoon REDCap Automation Suite

## Overview

This project is a sophisticated automation suite developed for macOS using Hammerspoon (Lua), AppleScript, and JavaScript. Its primary purpose is to streamline and accelerate repetitive data entry and navigation tasks within REDCap (Research Electronic Data Capture) projects via the Safari web browser. By automating complex sequences of actions, this suite significantly reduces manual effort, minimizes the potential for data entry errors, and enhances overall productivity for users managing REDCap data.

The development of this tool was driven by the need to handle intricate, multi-step workflows that are common in research data management, demonstrating an initiative to apply technical skills to solve practical, real-world efficiency challenges.

## Key Capabilities & Features

This automation suite demonstrates a framework for creating multiple distinct, hotkey-triggered workflows, highly configurable to handle common and custom interactions within diverse REDCap projects. The script provides examples of how these automations can be tailored to specific REDCap instruments and user needs:

* **Automated Form Completion:** Illustrates how to automate the filling of standard REDCap data collection forms. This can include pre-filling fields with default values (e.g., selecting "No" for a series of risk factor questions) and setting the REDCap form status (e.g., to "Complete" or "Unverified").
* **Multi-Step Data Processing & Record Management:** Showcases the ability to manage more complex REDCap workflows that span multiple views or actions. This includes capabilities such as:
    * Extracting specific data points (like Record IDs or participant identifiers) from one REDCap instrument or administrative page.
    * Copying extracted information to the clipboard for use in other applications or contexts.
    * Navigating programmatically to different REDCap pages or views.
    * Pasting extracted data (e.g., a Record ID) into fields to load existing REDCap records or to populate fields for new record creation.
* **Sequential Workflow Orchestration:** Demonstrates how multiple distinct REDCap automation sequences can be chained together and triggered by a single hotkey, managing application focus (e.g., ensuring Safari is active) between different operational stages. This allows for comprehensive end-to-end automation of larger REDCap tasks.
* **Interactive Data Entry with User Prompts:** Includes examples of workflows that begin by prompting the user for specific data points (e.g., dates, selections from predefined lists relevant to REDCap form fields like "Location of GIM" or "H. pylori Status") using native macOS dialogs. The script then uses this user-provided information to programmatically complete the relevant REDCap form fields.

**Core Technical Features:**

* **Cross-Application Control (macOS):** Leverages AppleScript to manage Safari (activation, tab control) and interact with system dialogs.
* **Precise Web Page Interaction:** Utilizes JavaScript executed within Safari to:
    * Reliably find and interact with specific HTML elements using CSS selectors and XPath expressions within REDCap pages.
    * Dynamically fill form fields (radio buttons, dropdowns, text inputs) in REDCap.
    * Trigger DOM events (e.g., `change`, `blur`) within REDCap forms.
* **Dynamic Waiting Mechanisms:** Implements robust polling loops (`waitForElement`, `waitForElementByXPath`, `waitForElementToDisappear`) to ensure the script only proceeds when REDCap page elements are loaded and ready, or when transient elements (like overlays) have disappeared. This makes the automation resilient to variations in page load times.
* **User Configuration:** Designed with a centralized `USER_CONFIG` section in Lua, allowing users to adapt selectors, default values, and timings to their specific REDCap projects and forms without altering core logic.
* **Error Handling & Logging:** Incorporates error checking at multiple levels (Lua, AppleScript, JavaScript) with console logging for debugging and status tracking during REDCap automation.
* **Global Hotkey System:** Uses Hammerspoon to provide convenient, system-wide hotkey access to trigger the automations when Safari and a REDCap page are active.
* **Contextual Awareness:** Includes a guard function (`onREDCap`) to ensure automations only run when Safari is the frontmost application and the active URL is part of a REDCap instance.

## Technical Skills Demonstrated

This project showcases proficiency and practical application of:

* **Scripting Languages:** Lua (for Hammerspoon), AppleScript, JavaScript.
* **Automation Techniques:** Desktop automation (Hammerspoon, AppleScript), web automation (JavaScript DOM manipulation for REDCap).
* **Web Technologies:** Understanding of HTML structure, CSS selectors, XPath, and browser event models as applied to REDCap interfaces.
* **Inter-Process Communication:** Orchestrating actions between Hammerspoon, AppleScript, and JavaScript running in Safari.
* **Problem Solving & Debugging:** Iteratively developing and refining complex, multi-step automation logic for REDCap, including robust error handling and dynamic waits.
* **Workflow Optimization:** Identifying inefficiencies in manual REDCap processes and designing automated solutions.
* **User Interface (UI) Interaction:** Programmatic control of UI elements, including handling user prompts for data input relevant to REDCap forms.

## Potential Impact

The primary impact of this automation suite is a significant increase in efficiency and a reduction in the potential for manual error during repetitive REDCap data entry tasks. For workflows that are performed frequently, the time savings can be substantial, freeing up user time for more critical tasks. The consistency of automated actions also contributes to higher data quality within REDCap projects.

## Technologies Used

* **Hammerspoon** (macOS Desktop Automation Framework)
* **Lua** (Scripting language for Hammerspoon)
* **AppleScript** (For macOS application control and UI scripting)
* **JavaScript** (For in-browser DOM manipulation and event handling in Safari, targeting REDCap)
* **CSS Selectors & XPath** (For web element identification within REDCap)

## Note on Configuration

This script is provided as a powerful template. To use it in a different REDCap environment or for different forms, the user **must** update the selectors, XPaths, field names, and other specific values within the `USER_CONFIG` table at the beginning of the `init.lua` file. Comments within this section guide the user on what each configuration item represents for their REDCap setup.

---

*This script is a personal project designed to improve workflow efficiency. It is not an official REDCap tool and should be used responsibly. Ensure all configurations are correct for your specific REDCap instance and forms before use.*
