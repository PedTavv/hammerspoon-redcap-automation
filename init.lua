hs.console.clearConsole()
print("Hammerspoon REDCap Automation Suite (De-identified) Loaded.")

hs.loadSpoon("Pasteboard") -- For clipboard access

-- =============================================================================
-- USER CONFIGURATION SECTION
-- =============================================================================
-- IMPORTANT: Users MUST update the placeholder values below to match their
-- specific REDCap project's HTML structure (selectors, XPaths, field names).
-- Comments indicate what each placeholder represents.
-- How to find selectors: Use Safari's Web Inspector (Develop > Show Web Inspector),
-- right-click on an element, and choose "Inspect Element".
-- Look for 'id', 'name', or unique 'class' attributes.
-- For XPaths, you can right-click the element in the Inspector and choose "Copy XPath".
-- -----------------------------------------------------------------------------
local USER_CONFIG = {
    -- General Settings
    safariBundleID = "com.apple.Safari",
    redcapUrlSignature = "/redcap/", -- Common part of REDCap URLs, used by the onREDCap guard.
    userInitials = "XX",             -- Replace XX with your initials (used in F2).

    -- F1 Automation: Typically for a standard data entry form.
    f1 = {
        -- XPath to click an element (e.g., a status icon) to open the main data entry form for F1.
        formTriggerXPath = "//*[@id='event_grid_table']/tbody/tr[1]/td[2]/a", -- Example: First instrument link in event grid
        
        -- CSS selectors for radio buttons to be set to "No" (or your desired default).
        -- Replace with actual IDs for your form's radio button inputs.
        -- The value '0' usually corresponds to "No" in REDCap yes/no fields.
        noOptionRadioIds = {
            "#your_f1_field1_radio_no", -- Example: #opt-field_name_0
            "#your_f1_field2_radio_no",
            "#your_f1_field3_radio_no",
            "#your_f1_field4_radio_no"
        },
        -- 'name' attribute of the "Form Status" dropdown (e.g., "all_patients_complete").
        formStatusDropdownName = "your_f1_form_status_dropdown_name",
        -- Value for "Complete" in the status dropdown (usually "2").
        formStatusValueComplete = "2",
        -- CSS selector for the "Save & Exit Form" button.
        saveAndExitButtonSelector = "#submit-btn-saverecord", -- Standard REDCap ID
        -- CSS selector for the "Record Status Dashboard" link.
        recordStatusDashboardLinkSelector = "#rsd-men-link" -- Standard REDCap ID
    },

    -- F2 Automation: For a multi-part workflow, often involving data extraction and pasting.
    f2 = {
        -- Part 1: Actions on the first form/view (e.g., an "Identifiers" form).
        -- CSS selector for the link/icon to open the first form (e.g., an instrument status icon).
        part1FormTriggerSelector = "#event_grid_table > tbody > tr > td.nowrap > a",
        -- 'name' attribute of the researcher initials input field.
        researcherInitialsInputName = "your_f2_initials_input_name",
        -- 'name' attribute of the "Complete" status dropdown on this first form.
        part1FormStatusDropdownName = "your_f2_part1_status_dropdown_name",
        -- CSS selector for the span containing the Record ID to be extracted.
        recordIdSpanSelector = "#record_id-tr > td.data.col-5 > span",
        -- 'name' attribute of the "Last Name" input field.
        lastNameInputName = "your_f2_lastname_input_name",
        -- 'name' attribute of the "First Name" input field.
        firstNameInputName = "your_f2_firstname_input_name",
        -- CSS selector for the "Save & Next Record" (or similar) button.
        saveAndNextButtonSelector = "#submit-btn-savenextrecord", -- Standard REDCap ID

        -- Part 2: Actions on a second form/view (e.g., a dashboard or record creation page).
        -- CSS selector for the input field where the extracted Record ID will be pasted.
        pasteTargetInputSelector = "#inputString", -- Example: A search or record ID input field
        -- CSS selector for the "Record Status Dashboard" link, used as a fallback if pasteTargetInputSelector isn't found.
        recordStatusDashboardLinkSelector = "#rsd-men-link" -- Standard REDCap ID
    },

    -- F5 Automation: Custom workflow for a specific form, with user prompts.
    f5 = {
        -- XPath to click an element to open the main data entry form for F5.
        formTriggerXPath = "//*[@id='event_grid_table']/tbody/tr[1]/td[2]/a", -- Example
        
        -- Specific radio button IDs for F5 workflow.
        field1_No_Id = "#your_f5_field1_radio_no",    -- e.g., Atrophic Gastritis - No
        field2_Yes_Id = "#your_f5_field2_radio_yes",   -- e.g., Gastric Intestinal Metaplasia - Yes
        
        -- 'name' attribute of the date input field (e.g., "first_date_criteria_met_2").
        dateInputName = "your_f5_date_input_name",
        -- 'name' attribute of the "Location of GIM" dropdown.
        locationGimDropdownName = "your_f5_gim_loc_dropdown_name",
        
        field3_No_Id = "#your_f5_field3_radio_no",    -- e.g., Gastric Neoplasia - No
        field4_Yes_Id = "#your_f5_field4_radio_yes",   -- e.g., Meets High Risk - Yes
        
        -- 'name' attribute of the "H. pylori Status" dropdown.
        hPyloriStatusDropdownName = "your_f5_hpylori_dropdown_name",
        -- 'name' attribute of the "Form Status" dropdown.
        formStatusDropdownName = "your_f5_form_status_dropdown_name",
        -- Value for "Unverified" in the status dropdown (usually "1").
        formStatusValueUnverified = "1",
        -- CSS selector for the "Save & Exit Form" button.
        saveAndExitButtonSelector = "#submit-btn-saverecord", -- Standard REDCap ID
        -- CSS selector for the "Record Status Dashboard" link.
        recordStatusDashboardLinkSelector = "#rsd-men-link" -- Standard REDCap ID
    },

    -- Common Selectors used across multiple automations.
    common = {
        -- Selector for page loading overlays that might temporarily cover elements.
        pageOverlaySelector = "#fade.black_overlay" -- Common overlay pattern
    },
    
    -- Delays (in seconds). Adjust these based on your system and network speed.
    delays = {
        applescriptGeneric = 0.25, -- General small delay within AppleScript steps.
        applescriptPolling = 0.2,  -- Polling interval for waitForElement functions.
        luaTimerActivation = 0.65, -- For hs.timer.doAfter when activating Safari.
        luaTimerLaunch = 1.95      -- For hs.timer.doAfter if Safari needs to be launched.
    }
}
-- =============================================================================
-- END OF USER CONFIGURATION SECTION
-- =============================================================================

-- Helper: Escapes double quotes for JS within AppleScript.
local function escapeJSQuotes(str)
    if type(str) ~= "string" then return "" end
    return str:gsub("\\", "\\\\"):gsub('"', '\\"')
end

-- Helper to prepare a JS string for safe embedding into AppleScript
local function escapeJSForAppleScriptEmbedding(js)
    if type(js) ~= "string" then return "" end
    return js:gsub("\\", "\\\\")
             :gsub("\"", "\\\"")
             :gsub("\n", "\\n")
             :gsub("\r", "")
end

-- Helper: Runs AppleScript with error handling.
local function runAppleScript(script, scriptName)
    scriptName = scriptName or "AppleScript"
    print("▶️ Running " .. scriptName .. "...")
    local ok, result, descriptor = hs.osascript.applescript(script)
    if not ok then
        local errMsg = "AppleScript Execution Failed: " .. (result or "Unknown osascript error")
        if descriptor and type(descriptor) == "table" then
             errMsg = errMsg .. " Details: " .. (descriptor["NSAppleScriptErrorBriefMessage"] or hs.inspect.inspect(descriptor))
        end
        print("❌ " .. scriptName .. ": " .. errMsg)
        return false, errMsg
    end
    local resultStr = tostring(result or "")
    if resultStr:find("^ERROR:") then
        print("❌ " .. scriptName .. ": Script returned an error: " .. resultStr)
        return false, resultStr
    end
    print("✅ " .. scriptName .. ": Execution successful. Result: '" .. resultStr .. "'")
    return true, resultStr
end

-- Helper: Generates AppleScript to switch Safari tabs.
local function switchToSafariTabAppleScript(tabIndex)
    return string.format([[
        try
            tell application "%s"
                activate
                if not running then error "Safari not running"
                if (count of windows) is 0 then error "No Safari windows open"
                tell front window
                     if (count of tabs) < %d then error "Tab index " & %d & " does not exist."
                     set current tab to tab %d
                end tell
                 delay %s 
            end tell
            return "OK"
         on error errMsg
            return "ERROR: Switching to tab %d: " & errMsg
         end try
    ]], USER_CONFIG.safariBundleID, tabIndex, tabIndex, tabIndex, USER_CONFIG.delays.applescriptGeneric, tabIndex)
end

-- Forward declaration for hotkey variables for onREDCap guard
local formKeyF1, formKeyF2, formKeyF3, formKeyF4, formKeyF5

-- Hotkey Guard: Only run macros if Safari is frontmost and URL matches REDCap signature.
local function onREDCap()
    local app = hs.application.frontmostApplication()
    if not (app and app:bundleID():lower() == USER_CONFIG.safariBundleID:lower()) then return false end
    local getURLScript = [[
        try
            tell application "Safari"
                if not running or (count of windows) is 0 then return ""
                return URL of current tab of front window
            end tell
        on error
            return ""
        end try
    ]]
    local ok, url, _ = hs.osascript.applescript(getURLScript)
    if ok and url and url:match(USER_CONFIG.redcapUrlSignature) then
        return true
    else
        local currentKey = hs.hotkey.currentBinding()
        if currentKey ~= formKeyF3 and currentKey ~= formKeyF4 and currentKey ~= formKeyF5 then 
             print("Guard: Conditions not met (Safari on REDCap page). URL: " .. tostring(url))
        end
        return false
    end
end

-- ==== F1 Automation ====
formModifiersF1 = {}
formKeyF1 = "f1" 

local function triggerF1()
    local scriptName = "F1 Automation"
    local appleScript = string.format([[
        on runJs(jsCode) 
            local jsResult
            try
                tell application "%s" to tell front window to tell current tab to set jsResult to do JavaScript jsCode
                if jsResult is missing value then return ""
                if (class of jsResult is string) and (jsResult starts with "ERROR:") then error quoted form of jsResult 
                return jsResult
            on error errMsg number errorNumber
                log "runJs Error: " & errMsg & " (Number: " & errorNumber & ")"
                if errMsg does not start with "ERROR:" then error quoted form of ("ERROR: JS Error - " & errMsg & " (Number: " & errorNumber & ")") 
                error quoted form of errMsg 
            end try
        end runJs
        on waitForElement(selector, timeoutSeconds)
            local jsCode, pollResult, escapedSelector
            log "waitForElement (CSS): Starting to wait for selector: " & selector
            set escapedSelector to do shell script "echo " & quoted form of selector & " | sed \"s/'/\\\\'/g\""
            set jsCode to "document.querySelector('" & escapedSelector & "') ? 'found' : 'not_found';"
            set startTime to current date
            repeat while ((current date) - startTime) < timeoutSeconds
                try
                    set pollResult to my runJs(jsCode)
                    if pollResult is "found" then return true
                on error
                end try
                delay %s 
            end repeat
            error "ERROR: Timeout waiting for element (CSS) to appear: " & selector
        end waitForElement
        on waitForElementByXPath(xpathExpression, timeoutSeconds)
            local jsCode, pollResult, escapedXPathForJS
            log "waitForElementByXPath: Starting to wait for XPath: " & xpathExpression
            set escapedXPathForJS to do shell script "echo " & quoted form of xpathExpression & " | sed 's/\"/\\\\\"/g'"
            set jsCode to "document.evaluate(\"" & escapedXPathForJS & "\", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue ? 'found' : 'not_found';"
            set startTime to current date
            repeat while ((current date) - startTime) < timeoutSeconds
                try
                    set pollResult to my runJs(jsCode)
                    if pollResult is "found" then return true
                on error
                end try
                delay %s 
            end repeat
            error "ERROR: Timeout waiting for element (XPath) to appear: " & xpathExpression
        end waitForElementByXPath
        on waitForElementToDisappear(selector, timeoutSeconds) 
            local jsCode, pollResult, escapedSelector
            log "waitForElementToDisappear: Starting to wait for disappearance of: " & selector
            set escapedSelector to do shell script "echo " & quoted form of selector & " | sed \"s/'/\\\\'/g\""
            set jsCode to "var el = document.querySelector('" & escapedSelector & "'); (!el || window.getComputedStyle(el).display === 'none' || window.getComputedStyle(el).visibility === 'hidden' || el.offsetWidth === 0) ? 'disappeared' : 'present';"
            set startTime to current date
            repeat while ((current date) - startTime) < timeoutSeconds
                try
                    set pollResult to my runJs(jsCode)
                    if pollResult is "disappeared" then return true
                on error
                end try
                delay %s 
            end repeat
            error "ERROR: Timeout waiting for element to disappear/hide: " & selector
        end waitForElementToDisappear
        try
            tell application "%s"
                if not running then error "Safari is not running."
                activate
            end tell
            delay %s 
            log "F1 Automation: Starting sequence."
            delay %s  
            set allPatientsXPath to "%s"
            log "F1 Step 1: Attempting to find and click 'All Patients' link with XPath: " & allPatientsXPath
            my waitForElementByXPath(allPatientsXPath, 10) 
            set escapedXPathForClickJS to do shell script "echo " & quoted form of allPatientsXPath & " | sed 's/\"/\\\\\"/g'"
            my runJs("(function(){ var el = document.evaluate(\"" & escapedXPathForClickJS & "\", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; if (!el) return 'ERROR: Form trigger (XPath) not found'; el.click(); return 'OK - Clicked form trigger'; })();")
            my waitForElement("%s", 10) 
            log "F1 Step 1b: First radio button found."
            my runJs("(function(){ var ids=JSON.parse('%s'); for(var i=0;i<ids.length;i++){var el=document.querySelector(ids[i]); if(!el) return 'ERROR: Missing radio button '+ids[i]; el.click();} return 'OK - Clicked radio buttons';})();")
            my waitForElement("select[name=\"%s\"]", 10) 
            my runJs("(function(){ var sel=document.querySelector('select[name=\"%s\"]'); if(!sel) return 'ERROR: Form Status dropdown not found'; sel.value='%s'; sel.dispatchEvent(new Event('change',{bubbles:true})); return 'OK - Set Form Status to Complete';})();")
            delay %s 
            my runJs("(function(){ var btn=document.querySelector('%s'); if(!btn) return 'ERROR: Save & Exit button not found'; btn.click(); return 'OK';})();")
            my waitForElementToDisappear("%s", 15) 
            my waitForElement("%s", 10) 
            my runJs("(function(){ try{var d=document.querySelector('%s'); if(!d) return 'ERROR: Dashboard link not found for click'; var r=d.getBoundingClientRect(); if(r.width===0||r.height===0||d.offsetWidth===0||d.offsetHeight===0){return 'ERROR: Dashboard link zero dimensions.';} var x=r.left+(r.width/2); var y=r.top+(r.height/2); var eAP=document.elementFromPoint(x,y); if(!eAP){return 'ERROR: No element at dashboard link center';} if(eAP===d||d.contains(eAP)){d.click(); return 'OK - Dashboard link click attempted';}else{return 'ERROR: Another element on top of dashboard link!';}}catch(e){return 'ERROR: JS Exception in dashboard click: '+e.message;}})();")
            return "F1 Complete"
        on error errMsg
            log "F1 Automation Error: " & errMsg 
            if errMsg does not start with "ERROR:" then return "ERROR: F1 Failed - " & errMsg
            return errMsg
        end try
    ]], USER_CONFIG.safariBundleID, 
        USER_CONFIG.delays.applescriptPolling, USER_CONFIG.delays.applescriptPolling, USER_CONFIG.delays.applescriptPolling,
        USER_CONFIG.safariBundleID, USER_CONFIG.delays.applescriptGeneric, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f1.formTriggerXPath,
        USER_CONFIG.f1.noOptionRadioIds[1], -- Assumes at least one ID is configured
        hs.json.encode(USER_CONFIG.f1.noOptionRadioIds), 
        USER_CONFIG.f1.formStatusDropdownName, USER_CONFIG.f1.formStatusDropdownName, USER_CONFIG.f1.formStatusValueComplete,
        USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f1.saveAndExitButtonSelector,
        USER_CONFIG.common.pageOverlaySelector,
        USER_CONFIG.f1.recordStatusDashboardLinkSelector, USER_CONFIG.f1.recordStatusDashboardLinkSelector
    )
    return runAppleScript(appleScript, scriptName) 
end

-- ==== F2 Automation ====
formModifiersF2 = {}
formKeyF2 = "f2" 

local function triggerF2()
    local scriptName = "F2 Automation"
    local recordIdStr = nil 
    print("--- F2 Automation: Initiated ---")

    print("--- F2 Automation: Starting Part 1 (Tab 2 Processing) ---")
    local scriptNameP1 = scriptName .. " - Part 1 (Tab 2 Processing)"
    local appleScriptPart1 = string.format([[
        on runJs(jsCode)
            local jsResult
            try
                tell application "%s" to tell front window to tell current tab to set jsResult to do JavaScript jsCode
                if jsResult is missing value then return ""
                if (class of jsResult is string) and (jsResult starts with "ERROR:") then error quoted form of jsResult 
                return jsResult
            on error errMsg number errorNumber
                if errMsg does not start with "ERROR:" then error quoted form of ("ERROR: JS Error - " & errMsg & " (Number: " & errorNumber & ")") 
                error quoted form of errMsg 
            end try
        end runJs
        on waitForElement(selector, timeoutSeconds) 
            local jsCode, pollResult
            set escapedSelector to do shell script "echo " & quoted form of selector & " | sed \"s/'/\\\\'/g\""
            set jsCode to "document.querySelector('" & escapedSelector & "') ? 'found' : 'not_found';"
            set startTime to current date
            repeat while ((current date) - startTime) < timeoutSeconds
                try
                    set pollResult to my runJs(jsCode)
                    if pollResult is "found" then return true
                on error
                end try
                delay %s 
            end repeat
            error "ERROR: Timeout waiting for element: " & selector
        end waitForElement
        set extractedID to ""
        set lastName to ""
        set firstName to ""
        try
            tell application "%s"
                activate
                if not running then error "Safari not running"
                tell front window
                    if (count of tabs) < 2 then error "Less than 2 tabs open"
                    set current tab to tab 2
                end tell
                delay %s 
            end tell
            my waitForElement("%s", 15)
            my runJs("(function(){var e=document.querySelector('%s'); if(e){e.click(); return 'OK';}else{return 'ERROR: Instrument status icon not found';}})();")
            my waitForElement("input[name=\"%s\"]", 15)
            delay %s 
            my runJs("(function(){var e=document.querySelector('input[name=\"%s\"]'); if(e){e.value='%s';e.dispatchEvent(new Event('input',{bubbles:true}));e.dispatchEvent(new Event('change',{bubbles:true}));e.dispatchEvent(new Event('blur',{bubbles:true})); return 'OK';}else{return 'ERROR: Initials input not found';}})();")
            delay %s 
            my runJs("(function(){var e=document.querySelector('select[name=\"%s\"]'); if(e){e.value='2';e.dispatchEvent(new Event('change',{bubbles:true}));e.dispatchEvent(new Event('input',{bubbles:true})); return 'OK';}else{return 'ERROR: Identifiers Complete dropdown not found';}})();")
            delay %s 
            set extractedID to my runJs("(function(){var e=document.querySelector('%s'); if(e){return (e.innerText||e.textContent||'').trim();}else{return 'ERROR: Record ID span not found';}})();")
            if extractedID is "" or extractedID starts with "ERROR:" then error "Extracted Record ID is invalid or not found."
            delay %s 
            set lastName to my runJs("(function(){var e=document.querySelector('input[name=\"%s\"]'); if(e){return e.value.trim();}else{return 'ERROR: Last Name input not found';}})();")
            if lastName starts with "ERROR:" then error lastName
            delay %s 
            set firstName to my runJs("(function(){var e=document.querySelector('input[name=\"%s\"]'); if(e){return e.value.trim();}else{return 'ERROR: First Name input not found';}})();")
            if firstName starts with "ERROR:" then error firstName
            delay %s 
            set the clipboard to (lastName & "," & firstName)
            delay %s 
            my runJs("(function(){var e=document.querySelector('%s'); if(e){e.click(); return 'OK';}else{return 'ERROR: Save & Next button not found';}})();")
            my waitForElement("%s", 15) 
            return extractedID 
        on error errMsg
            if errMsg does not start with "ERROR:" then return "ERROR: F2 Part 1 (Tab 2) Failed - " & errMsg
            return errMsg
        end try
    ]], USER_CONFIG.safariBundleID, USER_CONFIG.delays.applescriptPolling, USER_CONFIG.safariBundleID, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f2.part1FormTriggerSelector, USER_CONFIG.f2.part1FormTriggerSelector,
        USER_CONFIG.f2.researcherInitialsInputName, USER_CONFIG.delays.applescriptGeneric, USER_CONFIG.f2.researcherInitialsInputName, USER_CONFIG.userInitials,
        USER_CONFIG.delays.applescriptGeneric, USER_CONFIG.f2.part1FormStatusDropdownName, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f2.recordIdSpanSelector, USER_CONFIG.delays.applescriptGeneric / 5, 
        USER_CONFIG.f2.lastNameInputName, USER_CONFIG.delays.applescriptGeneric / 5,
        USER_CONFIG.f2.firstNameInputName, USER_CONFIG.delays.applescriptGeneric / 5,
        USER_CONFIG.delays.applescriptGeneric, USER_CONFIG.f2.saveAndNextButtonSelector,
        USER_CONFIG.f2.part1FormTriggerSelector 
    )
    local okP1, p1Result = runAppleScript(appleScriptPart1, scriptNameP1)
    
    if not okP1 then
        print("--- F2 Automation: Part 1 (Tab 2 Processing) FAILED. Halting F2. ---")
        return false 
    end
    recordIdStr = p1Result 
    print("--- F2 Automation: Part 1 (Tab 2 Processing) COMPLETED. Record ID: " .. recordIdStr .. " ---")

    print("--- F2 Automation: Starting Part 2 (Tab 1 Processing - Paste ID) ---")
    local scriptNameP2 = scriptName .. " - Part 2 (Tab 1 Processing)"
    local switchOk, switchResult = runAppleScript(switchToSafariTabAppleScript(1), scriptName .. " - Switch to Tab 1")
    if not switchOk then
        print("--- F2 Automation: Switching to Tab 1 FAILED. Halting F2. ---")
        return false 
    end

    if not recordIdStr or recordIdStr == "" then
        print("❌ F2 Error: Record ID is missing for Tab 1 actions. Halting F2.")
        return false 
    end

    local rawJsForPastingInTab1 = string.format([[
        (function(){
            const inputEl = document.querySelector('%s');
            if (!inputEl) return "ERROR: F2-P2-PASTE: Input field %s not found";
            inputEl.value = "%s"; 
            inputEl.dispatchEvent(new Event('input',{bubbles:true}));
            inputEl.dispatchEvent(new Event('change',{bubbles:true}));
            inputEl.dispatchEvent(new Event('blur',{bubbles:true})); 
            return "OK - Pasted Record ID and blurred input";
        })();
    ]], USER_CONFIG.f2.pasteTargetInputSelector, USER_CONFIG.f2.pasteTargetInputSelector, recordIdStr)
    local escapedJsForPasting = escapeJSForAppleScriptEmbedding(rawJsForPastingInTab1)

    local appleScriptPart2 = string.format([[
        on runJs(jsCode)
            local jsResult
            try
                tell application "%s" to tell front window to tell current tab to set jsResult to do JavaScript jsCode
                if jsResult is missing value then return ""
                if (class of jsResult is string) and (jsResult starts with "ERROR:") then error quoted form of jsResult 
                return jsResult as string
            on error errMsg number errorNumber
                if errMsg starts with "ERROR:" then error quoted form of errMsg
                else error quoted form of ("ERROR: JS System Error in runJs - " & errMsg & " (Number: " & errorNumber & ")")
                end if
            end try
        end runJs
        on waitForElement(selector, timeoutSeconds)
            local jsCode, pollResult, escapedSelector
            set escapedSelector to do shell script "echo " & quoted form of selector & " | sed \"s/'/\\\\'/g\""
            set jsCode to "document.querySelector('" & escapedSelector & "') ? 'found' : 'not_found';"
            set startTime to current date
            repeat while ((current date) - startTime) < timeoutSeconds
                try
                    set pollResult to my runJs(jsCode) 
                    if pollResult is "found" then return "found" 
                on error errMsgFromRunJs
                    log "waitForElement (F2P2): runJs threw error during poll for " & selector & ": " & errMsgFromRunJs
                end try
                delay %s 
            end repeat
            return "ERROR: Timeout waiting for element: " & selector 
        end waitForElement
        try
            log "F2 Part 2: Quick check for %s"
            set quickCheckResult to my runJs("document.querySelector('%s') ? 'found_quick_check' : 'not_found_quick_check';")
            delay %s 
            if quickCheckResult is "not_found_quick_check" or quickCheckResult starts with "ERROR:" then
                log "F2 Part 2: Input field not found on quick check. Attempting to click Record Status Dashboard."
                set dashboardLinkStatus to my waitForElement("%s", 10) 
                if dashboardLinkStatus starts with "ERROR:" then return dashboardLinkStatus 
                delay %s 
                set rsdClickResult to my runJs("(function(){ var d=document.querySelector('%s'); if(!d) return 'ERROR: F2-P2: Dashboard link not found for click'; d.click(); return 'OK - Clicked Dashboard link'; })();")
                if rsdClickResult starts with "ERROR:" then return rsdClickResult 
                delay %s 
                log "F2 Part 2: Checking for input field again after dashboard click."
                set finalInputWaitResult to my waitForElement("%s", 15) 
                if finalInputWaitResult starts with "ERROR:" then return finalInputWaitResult
                if finalInputWaitResult is not "found" then return "ERROR: F2-P2: Input field still not found after dashboard click."
            else if quickCheckResult is "found_quick_check" then
                 log "F2 Part 2: Input field found on quick check. Skipping dashboard click."
            else
                return "ERROR: F2 Part 2: Unexpected result from quick check for input field: " & quickCheckResult
            end if
            log "F2 Part 2: Proceeding to paste Record ID."
            delay %s 
            set pasteResult to my runJs("%s") 
            if pasteResult starts with "ERROR:" then return pasteResult
            return "F2 Part 2 (Tab 1 - Paste & Blur) Complete"
        on error errMsg 
             return "ERROR: F2 Part 2 (Tab 1) AppleScript System Error - " & errMsg
        end try
    ]], USER_CONFIG.safariBundleID, USER_CONFIG.delays.applescriptPolling,
        USER_CONFIG.f2.pasteTargetInputSelector, USER_CONFIG.f2.pasteTargetInputSelector, USER_CONFIG.delays.applescriptGeneric / 2.5,
        USER_CONFIG.f2.recordStatusDashboardLinkSelector, USER_CONFIG.delays.applescriptGeneric / 2.5,
        USER_CONFIG.f2.recordStatusDashboardLinkSelector, USER_CONFIG.delays.applescriptGeneric * 3.2, 
        USER_CONFIG.f2.pasteTargetInputSelector,
        USER_CONFIG.delays.applescriptGeneric / 1.5, escapedJsForPasting
    )

    local okP2, p2Result = runAppleScript(appleScriptPart2, scriptNameP2)
    if not okP2 then
        print("--- F2 Automation: Part 2 (Tab 1 Processing) FAILED: " .. p2Result .. ". Halting F2 before Preview step. ---")
        return false 
    end
    print("--- F2 Automation: Part 2 (Tab 1 Processing) COMPLETED. ---")

    print("--- F2 Automation: Starting Part 3 (Clipboard to User for Manual Preview Search) ---")
    local clipboardContent = hs.pasteboard.readString()
    if clipboardContent and clipboardContent ~= "" then
        hs.alert.show("F2: Name copied to clipboard:\n" .. clipboardContent .. "\n\nFor Preview: Cmd+F, then Cmd+V.", 5)
        print("F2: Name '" .. clipboardContent .. "' is on clipboard for manual Preview search.")
    else
        hs.alert.show("F2: Could not retrieve name for Preview from clipboard.", 3)
        print("F2: Name for Preview was not found on clipboard.")
        return false 
    end
    print("--- F2 Automation: All steps attempted. ---")
    return true 
end

-- ==== F3 Automation: Run F2 then F1 ====
formModifiersF3 = {}
formKeyF3 = "f3"

local function executeF1SequenceForF3_timer_callback(onREDCapFuncArg, triggerF1FuncArg)
    print("--- F3 (executeF1SequenceForF3_timer_callback): Checking REDCap conditions for F1 ---")
    if onREDCapFuncArg() then 
        local f1Success, _ = triggerF1FuncArg() 
        if f1Success then
            print("--- F3 Automation: F1 sequence COMPLETED successfully. ---")
        else
            print("--- F3 Automation: F1 sequence FAILED. ---")
        end
    else
        print("--- F3 (executeF1SequenceForF3_timer_callback): F1 Guard failed. Not on REDCap page. ---")
    end
    print("--- F3 Automation: Completed F1 part. ---")
end

local function triggerF3_main_logic()
    print("--- F3 Main Logic: Initiated ---")
    print("--- F3 Main Logic: Starting F2 sequence... ---")
    local f2Success, f2Result = triggerF2() 

    if f2Success then
        print("--- F3 Main Logic: F2 sequence COMPLETED successfully. Attempting to focus Safari for F1... ---")
        local safariApp = hs.application.get(USER_CONFIG.safariBundleID)
        if safariApp then
            if not safariApp:isRunning() then
                print("--- F3 Main Logic: Safari is not running. Launching Safari... ---")
                hs.application.launchOrFocus(USER_CONFIG.safariBundleID)
                hs.timer.doAfter(USER_CONFIG.delays.luaTimerLaunch, function() 
                    if safariApp:activate() then
                         print("--- F3 Main Logic: Safari activated after launch. Starting F1 sequence... ---")
                         hs.timer.doAfter(USER_CONFIG.delays.luaTimerActivation, function() executeF1SequenceForF3_timer_callback(onREDCap, triggerF1) end) 
                    else
                        print("--- F3 Main Logic: Failed to activate Safari after launch. F1 sequence will not run. ---")
                    end
                    print("--- F3 Main Logic: Completed (F1 run attempted or skipped). ---")
                end)
            elseif safariApp:activate() then
                 print("--- F3 Main Logic: Safari focused. Starting F1 sequence... ---")
                 hs.timer.doAfter(USER_CONFIG.delays.luaTimerActivation, function() executeF1SequenceForF3_timer_callback(onREDCap, triggerF1) end) 
            else
                print("--- F3 Main Logic: Failed to focus Safari. F1 sequence will not run reliably. ---")
                print("--- F3 Main Logic: Completed (F1 not run). ---")
            end
        else
            print("--- F3 Main Logic: Safari application not found. F1 sequence cannot run. ---")
            print("--- F3 Main Logic: Completed (F1 not run). ---")
        end
    else
        print("--- F3 Main Logic: F2 sequence FAILED. F1 sequence will not run. Result: " .. tostring(f2Result) .. " ---")
        print("--- F3 Main Logic: Completed (F2 failed). ---")
    end
end

-- ==== F4 Automation: Run F1 then F2 ====
formModifiersF4 = {}
formKeyF4 = "f4"

local function executeF2SequenceForF4_timer_callback(onREDCapFuncArg, triggerF2FuncArg)
    print("--- F4 (executeF2SequenceForF4_timer_callback): Checking REDCap conditions for F2 ---")
    if onREDCapFuncArg() then 
        local f2Success, _ = triggerF2FuncArg()
        if f2Success then
            print("--- F4 Automation: F2 sequence COMPLETED successfully. ---")
        else
            print("--- F4 Automation: F2 sequence FAILED. ---")
        end
    else
        print("--- F4 (executeF2SequenceForF4_timer_callback): F2 Guard failed. Not on REDCap page. ---")
    end
    print("--- F4 Automation: Completed F2 part. ---")
end

local function triggerF4_main_logic()
    print("--- F4 Main Logic: Initiated ---")
    print("--- F4 Main Logic: Starting F1 sequence... ---")
    local f1Success, f1Result = triggerF1()

    if f1Success then
        print("--- F4 Main Logic: F1 sequence COMPLETED successfully. Attempting to focus Safari for F2... ---")
        local safariApp = hs.application.get(USER_CONFIG.safariBundleID)
        if safariApp then
            if not safariApp:isRunning() then
                 print("--- F4 Main Logic: Safari is not running (unexpected after F1). Launching Safari... ---")
                hs.application.launchOrFocus(USER_CONFIG.safariBundleID)
                hs.timer.doAfter(USER_CONFIG.delays.luaTimerLaunch, function()  
                    if safariApp:activate() then
                         print("--- F4 Main Logic: Safari activated after launch. Starting F2 sequence... ---")
                         hs.timer.doAfter(USER_CONFIG.delays.luaTimerActivation, function() executeF2SequenceForF4_timer_callback(onREDCap, triggerF2) end) 
                    else
                        print("--- F4 Main Logic: Failed to activate Safari after launch. F2 sequence will not run. ---")
                    end
                    print("--- F4 Main Logic: Completed (F2 run attempted or skipped). ---")
                end)
            elseif safariApp:activate() then
                 print("--- F4 Main Logic: Safari focused. Starting F2 sequence... ---")
                 hs.timer.doAfter(USER_CONFIG.delays.luaTimerActivation, function() executeF2SequenceForF4_timer_callback(onREDCap, triggerF2) end) 
            else
                print("--- F4 Main Logic: Failed to focus Safari. F2 sequence will not run reliably. ---")
                print("--- F4 Main Logic: Completed (F2 not run). ---")
            end
        else
            print("--- F4 Main Logic: Safari application not found. F2 sequence cannot run. ---")
            print("--- F4 Main Logic: Completed (F2 not run). ---")
        end
    else
        print("--- F4 Main Logic: F1 sequence FAILED. F2 sequence will not run. Result: " .. tostring(f1Result) .. " ---")
        print("--- F4 Main Logic: Completed (F1 failed). ---")
    end
end
-- ==== F5 Automation: New Workflow ====
formModifiersF5 = {}
formKeyF5 = "f5"

local function triggerF5()
    local scriptName = "F5 Automation"
    local appleScript = string.format([[
        on runJs(jsCode)
            local jsResult
            try
                tell application "%s" to tell front window to tell current tab to set jsResult to do JavaScript jsCode
                if jsResult is missing value then return ""
                if (class of jsResult is string) and (jsResult starts with "ERROR:") then error quoted form of jsResult
                return jsResult
            on error errMsg number errorNumber
                log "runJs Error: " & errMsg & " (Number: " & errorNumber & ")"
                if errMsg does not start with "ERROR:" then error quoted form of ("ERROR: JS Error - " & errMsg & " (Number: " & errorNumber & ")")
                error quoted form of errMsg
            end try
        end runJs
        on waitForElement(selector, timeoutSeconds)
            local jsCode, pollResult, escapedSelector
            log "waitForElement (CSS): Starting to wait for selector: " & selector
            set escapedSelector to do shell script "echo " & quoted form of selector & " | sed \"s/'/\\\\'/g\""
            set jsCode to "document.querySelector('" & escapedSelector & "') ? 'found' : 'not_found';"
            set startTime to current date
            repeat while ((current date) - startTime) < timeoutSeconds
                try
                    set pollResult to my runJs(jsCode)
                    if pollResult is "found" then return true
                on error
                end try
                delay %s
            end repeat
            error "ERROR: Timeout waiting for element (CSS) to appear: " & selector
        end waitForElement
        on waitForElementByXPath(xpathExpression, timeoutSeconds)
            local jsCode, pollResult, escapedXPathForJS
            log "waitForElementByXPath: Starting to wait for XPath: " & xpathExpression
            set escapedXPathForJS to do shell script "echo " & quoted form of xpathExpression & " | sed 's/\"/\\\\\"/g'"
            set jsCode to "document.evaluate(\"" & escapedXPathForJS & "\", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue ? 'found' : 'not_found';"
            set startTime to current date
            repeat while ((current date) - startTime) < timeoutSeconds
                try
                    set pollResult to my runJs(jsCode)
                    if pollResult is "found" then return true
                on error
                end try
                delay %s
            end repeat
            error "ERROR: Timeout waiting for element (XPath) to appear: " & xpathExpression
        end waitForElementByXPath
        on waitForElementToDisappear(selector, timeoutSeconds) 
            local jsCode, pollResult, escapedSelector
            log "waitForElementToDisappear: Starting to wait for disappearance of: " & selector
            set escapedSelector to do shell script "echo " & quoted form of selector & " | sed \"s/'/\\\\'/g\""
            set jsCode to "var el = document.querySelector('" & escapedSelector & "'); (!el || window.getComputedStyle(el).display === 'none' || window.getComputedStyle(el).visibility === 'hidden' || el.offsetWidth === 0) ? 'disappeared' : 'present';"
            set startTime to current date
            repeat while ((current date) - startTime) < timeoutSeconds
                try
                    set pollResult to my runJs(jsCode)
                    if pollResult is "disappeared" then return true
                on error
                end try
                delay %s 
            end repeat
            error "ERROR: Timeout waiting for element to disappear/hide: " & selector
        end waitForElementToDisappear
        on clickElement(selector, description)
            log "Attempting to click " & description & " (" & selector & ")"
            my waitForElement(selector, 10)
            set clickResult to my runJs("(function(){ var el = document.querySelector('" & selector & "'); if (!el) return 'ERROR: " & description & " (" & selector & ") not found for click'; el.click(); return 'OK - Clicked " & description & "'; })();")
            if clickResult starts with "ERROR:" then error clickResult
            log clickResult
        end clickElement
        on setSelectValue(selector, val, description)
            log "Attempting to set " & description & " (" & selector & ") to value " & val
            my waitForElement(selector, 10)
            set setResult to my runJs("(function(){ var sel = document.querySelector('" & selector & "'); if (!sel) return 'ERROR: " & description & " (" & selector & ") not found'; sel.value = '" & val & "'; sel.dispatchEvent(new Event('change', {bubbles: true})); return 'OK - Set " & description & "'; })();")
            if setResult starts with "ERROR:" then error setResult
            log setResult
        end setSelectValue
        on setInputValue(selector, val, description)
            log "Attempting to set " & description & " (" & selector & ") to value " & val
            my waitForElement(selector, 10)
            set setResult to my runJs("(function(){ var inp = document.querySelector('" & selector & "'); if (!inp) return 'ERROR: " & description & " (" & selector & ") not found'; inp.value = '" & val & "'; inp.dispatchEvent(new Event('input', {bubbles:true})); inp.dispatchEvent(new Event('change', {bubbles:true})); inp.dispatchEvent(new Event('blur', {bubbles:true})); return 'OK - Set " & description & "'; })();")
            if setResult starts with "ERROR:" then error setResult
            log setResult
        end setInputValue
        try
            set dateDialogResult to display dialog "Enter First Date Criteria Met (DD/Mon/YYYY, e.g., 13/Jun/2017):" default answer "" with title "F5 Input"
            set enteredDateRaw to text returned of dateDialogResult
            if enteredDateRaw is "" then error "User did not enter a date."
            set oldDelimiters to AppleScript's text item delimiters
            set AppleScript's text item delimiters to "/" 
            set dateParts to text items of enteredDateRaw
            set AppleScript's text item delimiters to oldDelimiters
            if (count of dateParts) is not 3 then error "Invalid date format. Expected DD/Mon/YYYY."
            set dayPart to item 1 of dateParts
            set monthAbbr to item 2 of dateParts
            set yearPart to item 3 of dateParts
            if (length of dayPart) is 1 then set dayPart to "0" & dayPart
            set monthNum to "00"
            set monthAbbreviations to {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
            set monthNumbers to {"01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"}
            set monthFound to false
            repeat with i from 1 to (count of monthAbbreviations)
                if monthAbbr is (item i of monthAbbreviations) then
                    set monthNum to (item i of monthNumbers)
                    set monthFound to true
                    exit repeat
                end if
            end repeat
            if not monthFound then error "Invalid month abbreviation: " & monthAbbr
            set formattedDateForRedcap to monthNum & "-" & dayPart & "-" & yearPart 
            log "Formatted date for REDCap: " & formattedDateForRedcap
            set gimOptions to {"Proximal stomach (body, fundus)", "Distal stomach (antrum)", "Both proximal and distal", "Location of biopsies not specified"}
            set chosenGIMItem to choose from list gimOptions with prompt "Select Location of GIM:" default items {"Distal stomach (antrum)"} with title "F5 Input"
            if chosenGIMItem is false then error "User canceled Location of GIM selection."
            set chosenGIM to item 1 of chosenGIMItem
            set gimValue to "-1"
            if chosenGIM is "Proximal stomach (body, fundus)" then set gimValue to "0"
            if chosenGIM is "Distal stomach (antrum)" then set gimValue to "1"
            if chosenGIM is "Both proximal and distal" then set gimValue to "2"
            if chosenGIM is "Location of biopsies not specified" then set gimValue to "3"
            if gimValue is "-1" then error "Invalid GIM selection processed."
            set hpyloriOptions to {"no mention of H. pylori", "H. pylori negative", "H. pylori positive then later negative (presumed treated)", "H. pylori positive on last biopsy"}
            set chosenHpyloriItem to choose from list hpyloriOptions with prompt "Select H. pylori Status:" default items {"no mention of H. pylori"} with title "F5 Input"
            if chosenHpyloriItem is false then error "User canceled H. pylori Status selection."
            set chosenHpylori to item 1 of chosenHpyloriItem
            set hpyloriValue to "-1"
            if chosenHpylori is "no mention of H. pylori" then set hpyloriValue to "0"
            if chosenHpylori is "H. pylori negative" then set hpyloriValue to "1"
            if chosenHpylori is "H. pylori positive then later negative (presumed treated)" then set hpyloriValue to "2"
            if chosenHpylori is "H. pylori positive on last biopsy" then set hpyloriValue to "3"
            if hpyloriValue is "-1" then error "Invalid H. pylori selection processed."
            tell application "%s"
                if not running then error "Safari is not running."
                activate
            end tell
            delay %s 
            log "F5 Automation: Starting browser sequence."
            delay %s 
            set allPatientsXPath to "%s"
            log "F5 Step 1: Attempting to find and click 'All Patients' link with XPath: " & allPatientsXPath
            my waitForElementByXPath(allPatientsXPath, 10) 
            set escapedXPathForClickJS to do shell script "echo " & quoted form of allPatientsXPath & " | sed 's/\"/\\\\\"/g'"
            my runJs("(function(){ var el = document.evaluate(\"" & escapedXPathForClickJS & "\", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; if (!el) return 'ERROR: Form trigger (XPath) not found'; el.click(); return 'OK - Clicked Form Trigger'; })();")
            my waitForElement("%s", 10) 
            log "F5: Form loaded."
            my clickElement("%s", "Field 1 - No")
            delay %s
            my clickElement("%s", "Field 2 - Yes")
            delay %s
            my setInputValue("input[name=\"%s\"]", formattedDateForRedcap, "Date Criteria Met")
            delay %s
            my setSelectValue("select[name=\"%s\"]", gimValue, "Location of GIM")
            delay %s
            my clickElement("%s", "Field 3 - No")
            delay %s
            my clickElement("%s", "Field 4 - Yes")
            delay %s
            my setSelectValue("select[name=\"%s\"]", hpyloriValue, "H. pylori Status")
            delay %s
            my setSelectValue("select[name=\"%s\"]", "%s", "Form Status to Unverified") 
            delay %s
            my clickElement("%s", "Save & Exit Form button")
            my waitForElementToDisappear("%s", 15) 
            my waitForElement("%s", 10) 
            my clickElement("%s", "Record Status Dashboard link")
            return "F5 Complete"
        on error errMsg
            log "F5 Automation Error: " & errMsg 
            if errMsg does not start with "ERROR:" then return "ERROR: F5 Failed - " & errMsg
            return errMsg
        end try
    ]], USER_CONFIG.safariBundleID, USER_CONFIG.delays.applescriptPolling, USER_CONFIG.delays.applescriptPolling, USER_CONFIG.delays.applescriptPolling,
        USER_CONFIG.safariBundleID, USER_CONFIG.delays.applescriptGeneric, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f5.formTriggerXPath, USER_CONFIG.f5.field1_No_Id, -- Use the new generic ID
        USER_CONFIG.f5.field1_No_Id, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f5.field2_Yes_Id, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f5.dateInputName, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f5.locationGimDropdownName, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f5.field3_No_Id, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f5.field4_Yes_Id, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f5.hPyloriStatusDropdownName, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f5.formStatusDropdownName, USER_CONFIG.f5.formStatusValueUnverified, USER_CONFIG.delays.applescriptGeneric,
        USER_CONFIG.f5.saveAndExitButtonSelector,
        USER_CONFIG.common.pageOverlaySelector,
        USER_CONFIG.f5.recordStatusDashboardLinkSelector, USER_CONFIG.f5.recordStatusDashboardLinkSelector
    )
    return runAppleScript(appleScript, scriptName) 
end


-- Panic Key: Ctrl+Alt+Cmd+. to stop timers.
hs.hotkey.bind({'ctrl','alt','cmd'}, '.', function()
  print("!!! PANIC KEY: Stopping Timers !!!")
  hs.timer.stopAll()
  hs.alert.show("Automation Timers Stopped", 1)
end)
print("Bound Panic Key: Ctrl+Alt+Cmd+.")

-- New callback wrapper for hotkeys
local function createGuardedHotkeyCallback(actionFn, actionName)
    return function()
        print("Hotkey pressed for: " .. actionName)
        local safariApp = hs.application.get(USER_CONFIG.safariBundleID) 
        if not safariApp then
            print(actionName .. " Guard: Safari application not found on system.")
            return
        end

        local function proceed()
            if onREDCap() then
                print(actionName .. " Guard: REDCap conditions met. Running action.")
                actionFn()
            else
                print(actionName .. " Guard: Not on REDCap page or Safari not properly focused for REDCap check.")
            end
        end

        if not safariApp:isFrontmost() then
            print(actionName .. " Guard: Safari not frontmost. Activating...")
            if safariApp:activate() then
                hs.timer.doAfter(USER_CONFIG.delays.luaTimerActivation, proceed) 
            else
                print(actionName .. " Guard: Failed to activate Safari.")
            end
        else
            print(actionName .. " Guard: Safari is already frontmost.")
            proceed() 
        end
    end
end

-- Bind Hotkeys
hs.hotkey.bind(formModifiersF1, formKeyF1, createGuardedHotkeyCallback(triggerF1, "F1 Automation"))
print("Bound F1 -> REDCap 'All Patients' Form Automation")
hs.hotkey.bind(formModifiersF2, formKeyF2, createGuardedHotkeyCallback(triggerF2, "F2 Automation"))
print("Bound F2 -> REDCap Tab2 (Copy Name) -> Tab1 (Auto-Create Record) -> Preview (Search Name)")
hs.hotkey.bind(formModifiersF3, formKeyF3, createGuardedHotkeyCallback(triggerF3_main_logic, "F3 Automation"))
print("Bound F3 -> Run F2 then F1 Automation")
hs.hotkey.bind(formModifiersF4, formKeyF4, createGuardedHotkeyCallback(triggerF4_main_logic, "F4 Automation"))
print("Bound F4 -> Run F1 then F2 Automation")
hs.hotkey.bind(formModifiersF5, formKeyF5, createGuardedHotkeyCallback(triggerF5, "F5 Automation"))
print("Bound F5 -> REDCap 'All Patients' Custom Workflow")


print("Hammerspoon REDCap Hotkeys (F1, F2, F3, F4, F5) fully initialized.")
