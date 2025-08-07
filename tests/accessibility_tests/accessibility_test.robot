*** Settings ***
Library           SeleniumLibrary
Library           AxeLibrary

*** Variables ***
${URL}            https://www.w3.org/WAI/demos/bad/before/home.html

*** Test Cases ***
Accessibility Test
    Open Browser    ${URL}    Chrome
    Run Axe
    ${violations}=    Get Axe Violations
    Should Be Empty    ${violations}    Accessibility issues found: ${violations}
    [Teardown]    Close Browser
