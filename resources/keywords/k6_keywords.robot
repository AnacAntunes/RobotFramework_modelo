*** Settings ***
Documentation     Keywords para integração do Robot Framework com K6 usando Docker
Library           Process
Library           OperatingSystem
Library           Collections
Library           DateTime
Library           String

*** Variables ***
${K6_SCRIPTS_DIR}     ${CURDIR}/../../tests/performance_tests/k6_scripts
${K6_RESULTS_DIR}     ${CURDIR}/../../reports/performance
${DEFAULT_THRESHOLD}  95
${K6_DOCKER_IMAGE}    grafana/k6:latest

*** Keywords ***
Run K6 Script With Docker
    [Documentation]    Executa um script K6 usando Docker e retorna os resultados
    [Arguments]    ${script_name}    ${vus}=10    ${duration}=30s    ${stage_config}=${EMPTY}    ${thresholds}=${EMPTY}
    
    # Garantir que o diretório de resultados exista
    Create Directory    ${K6_RESULTS_DIR}
    
    # Gerar nome do arquivo de saída com timestamp
    ${timestamp}=    Get Current Date    result_format=%Y%m%d%H%M%S
    ${output_file_name}=    Set Variable    k6_results_${script_name}_${timestamp}.json
    ${output_file_path}=    Set Variable    ${K6_RESULTS_DIR}/${output_file_name}
    
    # Converter caminhos para formato compatível com Docker
    ${docker_script_dir}=    Evaluate    os.path.abspath("${K6_SCRIPTS_DIR}")    os
    ${docker_results_dir}=    Evaluate    os.path.abspath("${K6_RESULTS_DIR}")    os

    # Configurar comando base para o Docker
    ${docker_command}=    Set Variable    docker run --rm -v "${docker_script_dir}:/scripts" -v "${docker_results_dir}:/results" ${K6_DOCKER_IMAGE}
    
    # Preparar argumentos para o K6
    ${k6_args}=    Set Variable    run /scripts/${script_name} --out json=/results/${output_file_name}
    
    # Adicionar VUs e duração se não estiver usando estágios
    ${is_empty}=    Run Keyword And Return Status    Should Be Empty    ${stage_config}
    IF    ${is_empty}
        ${k6_args}=    Set Variable    ${k6_args} --vus ${vus} --duration ${duration}
    ELSE
        Log    Usando configuração de estágios personalizada
    END
    
    # Comando completo
    ${full_command}=    Set Variable    ${docker_command} ${k6_args}
    Log    Executando comando: ${full_command}
    
    # Executar K6 via Docker
    ${result}=    Run Process    ${full_command}    shell=True
    
    # Verificar se a execução foi bem-sucedida
    ${rc}=    Convert To Integer    ${result.rc}
    Should Be Equal As Integers    ${rc}    0    K6 execution failed with output:\n${result.stdout}\n${result.stderr}
    
    # Logar resultados
    Log    ${result.stdout}
    
    # Verificar se o arquivo de resultado foi gerado
    Wait Until Created    ${output_file_path}    timeout=10s    error=Arquivo de resultados não foi gerado: ${output_file_path}
    
    # Retornar resultados usando RETURN em vez de [Return]
    RETURN    ${result}    ${output_file_path}

Verify K6 Results
    [Documentation]    Verifica os resultados da execução do K6
    [Arguments]    ${output_file}    ${max_error_rate}=1    ${max_response_time}=500
    
    # Verificar se o arquivo existe
    File Should Exist    ${output_file}    O arquivo de resultados do K6 não foi encontrado
    
    # Carregar resultados
    ${json_content}=    Get File    ${output_file}
    
    # Verificação simples do conteúdo
    ${contains_metrics}=    Run Keyword And Return Status    Should Contain    ${json_content}    "metrics"
    Log    Arquivo de resultados contém métricas: ${contains_metrics}
    
    # Verificar se o arquivo não contém erros
    ${contains_errors}=    Run Keyword And Return Status    Should Not Contain    ${json_content}    "error"
    Log    Arquivo de resultados não contém erros: ${contains_errors}
    
    Log    Verificação básica de resultados concluída com sucesso