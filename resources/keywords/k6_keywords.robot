*** Settings ***
Documentation     Keywords para integração do Robot Framework com K6
Library           Process
Library           OperatingSystem
Library           Collections
Library           DateTime
Library           String
Library           JSONLibrary

*** Variables ***
${K6_SCRIPTS_DIR}     ${CURDIR}/../../tests/performance_tests/k6_scripts
${K6_RESULTS_DIR}     ${CURDIR}/../../reports/performance
${DEFAULT_THRESHOLD}  95

*** Keywords ***
Run K6 Script
    [Documentation]    Executa um script K6 e retorna os resultados
    [Arguments]    ${script_name}    ${vus}=10    ${duration}=30s    ${stage_config}=${EMPTY}    ${thresholds}=${EMPTY}
    
    # Garantir que o diretório de resultados exista
    Create Directory    ${K6_RESULTS_DIR}
    
    # Gerar nome do arquivo de saída com timestamp
    ${timestamp}=    Get Current Date    result_format=%Y%m%d%H%M%S
    ${output_file}=    Set Variable    ${K6_RESULTS_DIR}/k6_results_${script_name}_${timestamp}.json
    
    # Preparar argumentos para o K6
    ${args}=    Set Variable    run ${K6_SCRIPTS_DIR}/${script_name} --out json=${output_file}
    
    # Adicionar VUs e duração se não estiver usando estágios
    ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${stage_config}
    IF    ${is_empty}
        ${args}=    Set Variable    ${args} --vus ${vus} --duration ${duration}
    ELSE
        Log    Usando configuração de estágios personalizada
    END
    
    # Executar K6
    ${result}=    Run Process    k6    ${args}    shell=True
    
    # Verificar se a execução foi bem-sucedida
    Should Be Equal As Integers    ${result.rc}    0    K6 execution failed with output:\n${result.stdout}\n${result.stderr}
    
    # Logar resultados
    Log    ${result.stdout}
    
    # Retornar resultados
    [Return]    ${result}    ${output_file}

Verify K6 Results
    [Documentation]    Verifica os resultados da execução do K6
    [Arguments]    ${output_file}    ${max_error_rate}=1    ${max_response_time}=500
    
    # Verificar se o arquivo existe
    File Should Exist    ${output_file}    O arquivo de resultados do K6 não foi encontrado
    
    # Carregar resultados
    ${json_content}=    Get File    ${output_file}
    ${json_object}=    Evaluate    json.loads('''${json_content}''')    json
    
    # Verificar métricas
    # Adapte conforme suas necessidades e formato do JSON gerado pelo K6
    Log    Analisando resultados do teste de performance...
    
    # Exemplo de verificação de taxas de erro - ajuste conforme a estrutura real do JSON
    ${has_error_rate}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${json_object['metrics']}    http_req_failed
    
    IF    ${has_error_rate}
        ${error_rate}=    Set Variable    ${json_object['metrics']['http_req_failed']['values']['rate']}
        ${error_percentage}=    Evaluate    ${error_rate} * 100
        Should Be True    ${error_percentage} <= ${max_error_rate}
        ...    Taxa de erro (${error_percentage}%) excede o máximo permitido de ${max_error_rate}%
    ELSE
        Log    Métrica de taxa de erro não encontrada no resultado
    END
    
    # Exemplo de verificação de tempo de resposta - ajuste conforme a estrutura real do JSON
    ${has_response_time}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${json_object['metrics']}    http_req_duration
    
    IF    ${has_response_time}
        ${response_time}=    Set Variable    ${json_object['metrics']['http_req_duration']['values']['p95']}
        Should Be True    ${response_time} <= ${max_response_time}
        ...    Tempo de resposta P95 (${response_time}ms) excede o máximo permitido de ${max_response_time}ms
    ELSE
        Log    Métrica de tempo de resposta não encontrada no resultado
    END
    
    Log    Verificação de resultados concluída com sucesso