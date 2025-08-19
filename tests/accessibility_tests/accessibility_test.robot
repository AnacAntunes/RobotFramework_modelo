*** Settings ***
Documentation     Executa axe-core via Selenium em uma lista de URLs e salva JSON por página.
Library           SeleniumLibrary
Library           OperatingSystem
Library           String
Library           ${CURDIR}/../../resources/libraries/a11y_keywords.py

Suite Setup       Preparar Navegador
Suite Teardown    Close All Browsers

*** Variables ***
${BROWSER}        chrome
${OUTPUT_DIR}     ${EXECDIR}/results/accessibility
${FAIL_ON}        serious
${URLS_FILE}      ${CURDIR}/../../resources/a11y_urls.txt
${WIN_WIDTH}      1366
${WIN_HEIGHT}     900

*** Keywords ***
Preparar Navegador
    Open Browser       about:blank    ${BROWSER}    headless=True
    Set Window Size    ${WIN_WIDTH}   ${WIN_HEIGHT}

Auditar URL
    [Arguments]    ${url}
    Go To    ${url}
    ${safe}=    Replace String Using Regexp    ${url}    [^a-zA-Z0-9\-]    -
    ${res}=    Run Axe And Save    ${OUTPUT_DIR}    ${safe}    ${FAIL_ON}
    Log To Console    \n[AXE] ${url} => ${res}

*** Test Cases ***
A11y Smoke - Lista de Páginas
    ${raw}=    Get File    ${URLS_FILE}
    @{URLS}=   Split To Lines    ${raw}
    FOR    ${url}    IN    @{URLS}
        Run Keyword If    '${url}'!=''    Auditar URL    ${url}
    END
=======
Documentation     Suite para validar acessibilidade (WCAG) com axe-core via SeleniumLibrary.
Library           SeleniumLibrary
Library           OperatingSystem
Library           Collections
Suite Setup       Preparar Ambiente
Suite Teardown    Finalizar Ambiente
Test Setup        Abrir Página
Test Teardown     Fechar Página
# Captura screenshot automático nas falhas
Library           BuiltIn

*** Variables ***
${URL}                     https://www.w3.org/WAI/ARIA/apg/example-index/
# Caminho local do axe; mantenha o arquivo em tests/resources/axe.min.js
${AXE_SCRIPT}              ${CURDIR}/../resources/axe.min.js
# Fallback CDN caso o arquivo local não exista
${AXE_CDN}                 https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.9.1/axe.min.js
# Parametrizáveis via linha de comando/CI
${BROWSER}                 headlesschrome
${MAX_VIOLATIONS}          0
# Filtros WCAG — ajuste conforme necessidade (ex.: adicionar 'wcag21aa')
@{RUN_ONLY_TAGS}           wcag2a    wcag2aa

*** Test Cases ***
Validar Acessibilidade com Axe-Core
    [Documentation]    Executa o axe-core para validar critérios WCAG 2 A/AA na página alvo.
    [Tags]             accessibility    wcag    wcag2a    wcag2aa
    Carregar Axe (Local Ou CDN)
    ${results}=        Executar Axe E Obter Resultados    @{RUN_ONLY_TAGS}
    Imprimir Resumo De Violacoes    ${results}
    Validar Que Nao Ha Violacoes    ${results}    ${MAX_VIOLATIONS}

*** Keywords ***
Preparar Ambiente
    # Garante logs úteis e screenshot automático nas falhas
    Register Keyword To Run On Failure    Capture Page Screenshot

Finalizar Ambiente
    Close All Browsers

Abrir Página
    Open Browser    ${URL}    ${BROWSER}
    Set Selenium Implicit Wait    2 s
    # Opcional: garantir que a página carregou algo significativo
    Wait Until Page Contains Element    css:body    10 s

Fechar Página
    Run Keyword And Ignore Error    Capture Page Screenshot
    Close Browser

Carregar Axe (Local Ou CDN)
    # Tenta carregar do arquivo local; se não existir, injeta via CDN
    ${existe}=    Run Keyword And Return Status    File Should Exist    ${AXE_SCRIPT}
    Run Keyword If    ${existe}    Carregar Axe Local
    ...    ELSE    Carregar Axe Via CDN
    Aguardar Axe Disponivel

Carregar Axe Local
    ${axe_script}=    Get File    ${AXE_SCRIPT}
    Execute JavaScript    ${axe_script}

Carregar Axe Via CDN
    Execute Async JavaScript
    ...    var url = arguments[0];
    ...    var cb = arguments[arguments.length - 1];
    ...    var s = document.createElement('script');
    ...    s.src = url;
    ...    s.onload = function(){ cb(true); };
    ...    s.onerror = function(){ cb(false); };
    ...    document.head.appendChild(s);
    ...    return;
    ...    ${AXE_CDN}

Aguardar Axe Disponivel
    Wait Until Keyword Succeeds    10x    1s    Verificar Axe Disponivel

Verificar Axe Disponivel
    ${ready}=    Execute JavaScript    return !!(window.axe && window.axe.run);
    Should Be True    ${ready}    msg=axe-core não disponível no contexto da página.

Executar Axe E Obter Resultados
    [Arguments]    @{tags}
    # Executa apenas WCAG A/AA para tornar o scan mais rápido e objetivo
    ${script}=    Set Variable
    ...    return axe.run(document, {
    ...      runOnly: { type: 'tag', values: arguments[0] },
    ...      resultTypes: ['violations']
    ...    });
    ${result}=    Execute Async JavaScript    var cb=arguments[arguments.length-1]; ${script}.then(r=>cb(r)).catch(e=>cb({error:e && e.message || String(e)}));
    Run Keyword If    '${result}'=='None'    Fail    Falha ao executar axe.run (resultado vazio).
    Run Keyword If    'error' in ${result}    Fail    Erro no axe.run: ${result['error']}
    [Return]    ${result}

Imprimir Resumo De Violacoes
    [Arguments]    ${result}
    ${violations}=    Set Variable    ${result['violations']}
    ${count}=         Get Length      ${violations}
    Log To Console    \n===== Resumo de Violações WCAG (total: ${count}) =====
    FOR    ${v}    IN    @{violations}
        ${id}=        Get From Dictionary    ${v}    id
        ${impact}=    Get From Dictionary    ${v}    impact
        ${nodes}=     Get From Dictionary    ${v}    nodes
        ${ncount}=    Get Length    ${nodes}
        Log To Console    - ${id} | impacto: ${impact} | ocorrências: ${ncount}
    END
    # Salva um JSON resumido no log do Robot para consulta posterior
    Log    ${result}

Validar Que Nao Ha Violacoes
    [Arguments]    ${result}    ${max}
    ${violations}=    Set Variable    ${result['violations']}
    ${count}=         Get Length      ${violations}
    Log    Quantidade de violações WCAG encontradas: ${count}
    Should Be True    ${count} <= ${max}    msg=Foram encontradas ${count} violações de acessibilidade (limite permitido: ${max}).
    Log    Nenhuma violação acima do limite configurado.