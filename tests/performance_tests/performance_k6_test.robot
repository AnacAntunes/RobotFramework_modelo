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
    [Documentation]    Executa um teste K6 básico com Docker
    [Tags]    performance    api    k6
    
    # Criar diretórios necessários
    Create Directory    ${K6_SCRIPTS_DIR}
    Create Directory    ${REPORT_DIR}
    
    # Criar um script K6 simples
    ${script_content}=    Catenate    SEPARATOR=\n
    ...    import http from 'k6/http';
    ...    import { check } from 'k6';
    ...    
    ...    export const options = {
    ...      vus: 5,
    ...      duration: '5s',
    ...    };
    ...    
    ...    export default function() {
    ...      const res = http.get('https://test.k6.io/');
    ...      check(res, {
    ...        'status is 200': (r) => r.status === 200,
    ...      });
    ...    }
    
    ${script_file}=    Set Variable    ${K6_SCRIPTS_DIR}/simple_test.js
    Create File    ${script_file}    ${script_content}
    
    # Executar o K6 via Docker
    ${result}=    Run Process
    ...    docker run --rm -v ${K6_SCRIPTS_DIR}:/scripts grafana/k6:latest run /scripts/simple_test.js
    ...    shell=True
    
    # Logar resultados
    Log    ${result.stdout}
    Log    ${result.stderr}
    
    # Verificar se o teste foi executado com sucesso
    Should Be Equal As Integers    ${result.rc}    0    Erro ao executar teste K6: ${result.stderr}
    Should Contain    ${result.stdout}    running
    
    # Salvar resultado em arquivo para referência
    ${timestamp}=    Get Current Date    result_format=%Y%m%d%H%M%S
    ${output_file}=    Set Variable    ${REPORT_DIR}/k6_output_${timestamp}.txt
    Create File    ${output_file}    ${result.stdout}
    
    Log    Teste K6 executado com sucesso. Resultado salvo em: ${output_file}