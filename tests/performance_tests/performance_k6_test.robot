*** Settings ***
Documentation     Testes de performance simplificados com K6
Library           Process
Library           OperatingSystem
Library           DateTime

*** Variables ***
${K6_SCRIPTS_DIR}     ${CURDIR}/k6_scripts
${REPORT_DIR}         ${CURDIR}/../../reports/performance

*** Test Cases ***
Executar Teste K6 Básico
    [Documentation]    Executa o teste básico de carga usando script existente
    [Tags]    performance    api    k6
    
    # Garantir que o diretório de relatórios existe
    Create Directory    ${REPORT_DIR}
    
    # Verificar se o script existe
    File Should Exist    ${K6_SCRIPTS_DIR}/basic_load_test.js
    
    # Executar o script k6 via Docker com opções simplificadas
    ${result}=    Run Process
    ...    docker run --rm -v ${K6_SCRIPTS_DIR}:/scripts grafana/k6:latest run /scripts/basic_load_test.js --duration 10s --vus 5
    ...    shell=True
    
    # Salvar resultado
    ${timestamp}=    Get Current Date    result_format=%Y%m%d%H%M%S
    ${output_file}=    Set Variable    ${REPORT_DIR}/basic_load_test_${timestamp}.log
    Create File    ${output_file}    ${result.stdout}
    
    # Verificações simplificadas
    Should Be Equal As Integers    ${result.rc}    0    Falha na execução do teste k6: ${result.stderr}
    Should Contain    ${result.stdout}    ✓ status is 200    Teste não encontrou status 200
    Should Not Contain    ${result.stdout}    ERRO    O teste contém erros
    
    Log    Teste de carga básico executado com sucesso

Verificar Performance da API de Posts
    [Documentation]    Executa o teste de API de posts usando script existente
    [Tags]    performance    api    k6    posts
    
    # Garantir que o diretório de relatórios existe
    Create Directory    ${REPORT_DIR}
    
    # Verificar se o script existe
    File Should Exist    ${K6_SCRIPTS_DIR}/posts_api_test.js
    
    # Executar o script k6 via Docker com opções simplificadas
    ${result}=    Run Process
    ...    docker run --rm -v ${K6_SCRIPTS_DIR}:/scripts grafana/k6:latest run /scripts/posts_api_test.js --duration 5s --vus 3
    ...    shell=True
    
    # Salvar resultado
    ${timestamp}=    Get Current Date    result_format=%Y%m%d%H%M%S
    ${output_file}=    Set Variable    ${REPORT_DIR}/posts_api_test_${timestamp}.log
    Create File    ${output_file}    ${result.stdout}
    
    # Verificações simplificadas
    Should Be Equal As Integers    ${result.rc}    0    Falha na execução do teste k6: ${result.stderr}
    Should Contain    ${result.stdout}    ✓ status is 200 or 201    Teste não encontrou status 200/201
    Should Not Contain    ${result.stdout}    ERRO    O teste contém erros
    
    Log    Teste de API de posts executado com sucesso