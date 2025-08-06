*** Settings ***
Documentation     Suite de testes de performance usando K6
Resource          ../../resources/keywords/k6_keywords.robot
Library           Collections
Library           OperatingSystem

*** Variables ***
${API_BASE_URL}       https://jsonplaceholder.typicode.com
${VUS}                10
${DURATION}           30s
${ERROR_THRESHOLD}    1
${RESPONSE_THRESHOLD} 500

*** Test Cases ***
Executar Teste de Carga Básico
    [Documentation]    Executa um teste de carga básico com K6
    [Tags]    performance    api    k6
    
    # Verificar se o diretório de scripts existe, se não, criar
    Create Directory    ${K6_SCRIPTS_DIR}
    
    # Criar script de teste K6 básico se não existir
    ${script_path}=    Set Variable    ${K6_SCRIPTS_DIR}/basic_load_test.js
    ${script_exists}=    Run Keyword And Return Status    File Should Exist    ${script_path}
    
    IF    not ${script_exists}
        ${script_content}=    Create K6 Basic Load Test Script
        Create File    ${script_path}    ${script_content}
    END
    
    ${result}    ${output_file}=    Run K6 Script    basic_load_test.js    ${VUS}    ${DURATION}
    Log    K6 Test Output: ${result.stdout}
    Verify K6 Results    ${output_file}    ${ERROR_THRESHOLD}    ${RESPONSE_THRESHOLD}

Verificar Performance da API de Posts
    [Documentation]    Teste específico para a API de posts
    [Tags]    performance    api    k6    posts
    
    # Verificar se o diretório de scripts existe, se não, criar
    Create Directory    ${K6_SCRIPTS_DIR}
    
    # Exemplo de como você pode criar um script K6 dinamicamente
    ${script_content}=    Create K6 Script For API Endpoint    /posts    GET
    
    # Salvar o script
    ${script_path}=    Set Variable    ${K6_SCRIPTS_DIR}/posts_api_test.js
    Create File    ${script_path}    ${script_content}
    
    # Executar o script
    ${result}    ${output_file}=    Run K6 Script    posts_api_test.js    5    15s
    
    # Verificar resultados
    Log    K6 Test Output: ${result.stdout}
    Verify K6 Results    ${output_file}    0.5    300

*** Keywords ***
Create K6 Basic Load Test Script
    [Documentation]    Cria um script K6 básico para teste de carga
    
    ${script}=    Catenate    SEPARATOR=\n
    ...    import http from 'k6/http';
    ...    import { check, sleep } from 'k6';
    ...    import { Counter, Rate } from 'k6/metrics';
    ...
    ...    // Métricas personalizadas
    ...    const errors = new Counter('errors');
    ...    const successRate = new Rate('successful_requests');
    ...
    ...    // Configurações do teste
    ...    export const options = {
    ...      // Estas podem ser sobrescritas pela linha de comando
    ...      vus: 10,
    ...      duration: '30s',
    ...      
    ...      // Limiares de qualidade
    ...      thresholds: {
    ...        http_req_duration: ['p(95)<500'],  // 95% das requisições devem ser < 500ms
    ...        'http_req_failed': ['rate<0.01'],  // Taxa de erro < 1%
    ...        'successful_requests': ['rate>0.95'],  // Taxa de sucesso > 95%
    ...      },
    ...    };
    ...
    ...    // Função principal de teste
    ...    export default function() {
    ...      // Teste GET
    ...      const getResponse = http.get('https://jsonplaceholder.typicode.com/posts');
    ...      
    ...      const getChecks = check(getResponse, {
    ...        'status is 200': (r) => r.status === 200,
    ...        'response time < 200ms': (r) => r.timings.duration < 200,
    ...        'response body not empty': (r) => r.body.length > 0,
    ...      });
    ...      
    ...      successRate.add(getChecks);
    ...      
    ...      if (!getChecks) {
    ...        errors.add(1);
    ...        console.log(`Falha no GET: ${getResponse.status}, duração: ${getResponse.timings.duration}ms`);
    ...      }
    ...      
    ...      // Teste POST
    ...      const payload = JSON.stringify({
    ...        title: 'foo',
    ...        body: 'bar',
    ...        userId: 1
    ...      });
    ...      
    ...      const params = {
    ...        headers: {
    ...          'Content-Type': 'application/json',
    ...        },
    ...      };
    ...      
    ...      const postResponse = http.post('https://jsonplaceholder.typicode.com/posts', payload, params);
    ...      
    ...      const postChecks = check(postResponse, {
    ...        'status is 201': (r) => r.status === 201,
    ...        'has id': (r) => r.json().id !== undefined,
    ...      });
    ...      
    ...      successRate.add(postChecks);
    ...      
    ...      if (!postChecks) {
    ...        errors.add(1);
    ...        console.log(`Falha no POST: ${postResponse.status}, duração: ${postResponse.timings.duration}ms`);
    ...      }
    ...      
    ...      // Pausa para simular comportamento real de usuário
    ...      sleep(Math.random() * 2 + 1); // Entre 1-3 segundos
    ...    }

    [Return]    ${script}

Create K6 Script For API Endpoint
    [Documentation]    Cria um script K6 para testar um endpoint específico
    [Arguments]    ${endpoint}    ${method}=GET    ${payload}=${EMPTY}
    
    ${script}=    Catenate    SEPARATOR=\n
    ...    import http from 'k6/http';
    ...    import { check, sleep } from 'k6';
    ...
    ...    export const options = {
    ...      vus: 5,
    ...      duration: '15s',
    ...      thresholds: {
    ...        http_req_duration: ['p(95)<300'],
    ...        http_req_failed: ['rate<0.005'],
    ...      },
    ...    };
    ...
    ...    export default function() {
    ...      const url = '${API_BASE_URL}${endpoint}';
    ...      let response;
    ...
    
    ${is_get}=    Run Keyword And Return Status    Should Be Equal    ${method}    GET
    ${is_post}=    Run Keyword And Return Status    Should Be Equal    ${method}    POST
    
    IF    ${is_get}
        ${script}=    Catenate    SEPARATOR=\n    ${script}
        ...      response = http.get(url);
    ELSE IF    ${is_post}
        ${script}=    Catenate    SEPARATOR=\n    ${script}
        ...      let payload = { title: "test", body: "test body", userId: 1 };
        
        ${has_payload}=    Run Keyword And Return Status    Should Not Be Empty    ${payload}
        IF    ${has_payload}
            ${script}=    Catenate    SEPARATOR=\n    ${script}
            ...      payload = ${payload};
        END
        
        ${script}=    Catenate    SEPARATOR=\n    ${script}
        ...      const params = { headers: { 'Content-Type': 'application/json' } };
        ...      response = http.post(url, JSON.stringify(payload), params);
    END
    
    ${script}=    Catenate    SEPARATOR=\n    ${script}
    ...
    ...      check(response, {
    ...        'status is 200 or 201': (r) => r.status === 200 || r.status === 201,
    ...        'has content': (r) => r.body.length > 0,
    ...      });
    ...
    ...      sleep(1);
    ...    }
    
    [Return]    ${script}