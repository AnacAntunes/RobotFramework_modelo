*** Settings ***
Documentation     Testes de acessibilidade usando Pa11y
Library           Process
Library           OperatingSystem
Library           Collections
Library           DateTime
Library           String

*** Variables ***
${CONFIG_FILE}        ${CURDIR}/pa11y_config.json
${REPORT_DIR}         ${CURDIR}/../../reports/accessibility
${SITES_TO_TEST}      https://www.example.com/    https://www.google.com/

*** Test Cases ***
Verificar Acessibilidade com Pa11y
    [Documentation]    Executa testes de acessibilidade usando Pa11y via Docker
    [Tags]    accessibility    wcag    a11y
    
    Create Directory    ${REPORT_DIR}
    
    FOR    ${site}    IN    @{SITES_TO_TEST}
        ${site_name}=    Convert URL to Filename    ${site}
        ${timestamp}=    Get Current Date    result_format=%Y%m%d%H%M%S
        ${report_file}=    Set Variable    ${REPORT_DIR}/${site_name}_${timestamp}.html
        
        Run Pa11y Test    ${site}    ${report_file}
        Verify Accessibility Results    ${site}    ${report_file}
    END

*** Keywords ***
Convert URL to Filename
    [Documentation]    Converte URL em um nome de arquivo válido
    [Arguments]    ${url}
    
    ${filename}=    Replace String    ${url}    http://    
    ${filename}=    Replace String    ${filename}    https://    
    ${filename}=    Replace String    ${filename}    /    _
    ${filename}=    Replace String    ${filename}    :    _
    ${filename}=    Replace String    ${filename}    .    -
    
    RETURN    ${filename}

Run Pa11y Test
    [Documentation]    Executa Pa11y contra um site específico
    [Arguments]    ${url}    ${report_file}
    
    ${result}=    Run Process
    ...    docker run --rm -v ${REPORT_DIR}:/reports djlechuck/pa11y-ci ${url} --reporter html > ${report_file}
    ...    shell=True
    
    Should Be Equal As Integers    ${result.rc}    0    Falha ao executar teste de acessibilidade para ${url}: ${result.stderr}
    Log    Teste de acessibilidade executado em: ${url}
    
    # Criar um arquivo de log simples com os resultados
    ${log_file}=    Replace String    ${report_file}    .html    .log
    Create File    ${log_file}    URL: ${url}\n\nSTDOUT:\n${result.stdout}\n\nSTDERR:\n${result.stderr}

Verify Accessibility Results
    [Documentation]    Verifica os resultados do teste de acessibilidade
    [Arguments]    ${url}    ${report_file}
    
    File Should Exist    ${report_file}    Arquivo de relatório não foi gerado para ${url}
    
    ${content}=    Get File    ${report_file}
    ${has_errors}=    Run Keyword And Return Status    Should Not Contain    ${content}    Error:
    
    IF    ${has_errors}
        Log    Site ${url} não tem erros de acessibilidade críticos
    ELSE
        Log    Site ${url} tem erros de acessibilidade que precisam ser corrigidos    level=WARN
    END  
