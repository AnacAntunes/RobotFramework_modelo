*** Settings ***
Documentation     Teste de acessibilidade com análise baseada em regras WCAG
Library           Process
Library           OperatingSystem
Library           Collections
Library           DateTime
Library           String

*** Variables ***
${REPORT_DIR}         ${CURDIR}/../../reports/accessibility
# Site real para teste (W3Schools - site popular com conteúdo técnico)
${URL_TO_TEST}        https://www.w3schools.com/

*** Test Cases ***
Verificar Conformidade WCAG Com Axe
    [Documentation]    Executa análise de acessibilidade com axe-core e identifica violações WCAG
    [Tags]    accessibility    wcag    axe
    
    # Criar diretório para relatórios
    Create Directory    ${REPORT_DIR}
    
    # Obter timestamp para arquivos únicos
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    
    # Criar script de teste
    ${script_path}=    Create Axe Test Script
    
    # Executar axe-core
    ${result}=    Run Process    
    ...    node ${script_path} ${URL_TO_TEST} ${REPORT_DIR}/axe_results_${timestamp}.json
    ...    shell=True
    
    # Verificar execução
    Should Be Equal As Integers    ${result.rc}    0    Falha ao executar axe-core: ${result.stderr}
    
    # Obter o caminho do relatório
    ${json_report}=    Set Variable    ${REPORT_DIR}/axe_results_${timestamp}.json
    
    # Verificar se o relatório foi gerado
    File Should Exist    ${json_report}
    
    # Processar os resultados e gerar relatório amigável
    ${markdown_report}=    Process Axe Results    ${json_report}    ${URL_TO_TEST}    ${timestamp}
    
    # Logar resumo
    Log    ${result.stdout}
    
    # Criar arquivo com violações específicas WCAG
    ${wcag_report}=    Create WCAG Violations Report    ${json_report}    ${URL_TO_TEST}    ${timestamp}
    
    Log    Teste de acessibilidade WCAG concluído com sucesso.

*** Keywords ***
Create Axe Test Script
    [Documentation]    Cria script Node.js para executar axe-core
    
    # Criar diretório temporário
    Create Directory    ${REPORT_DIR}/temp
    
    # Criar package.json
    ${package_json}=    Catenate    SEPARATOR=\n
    ...    {
    ...      "type": "module",
    ...      "dependencies": {
    ...        "axe-core": "^4.7.0",
    ...        "playwright": "^1.36.0"
    ...      }
    ...    }
    
    Create File    ${REPORT_DIR}/temp/package.json    ${package_json}
    
    # Criar script de teste
    ${script_content}=    Catenate    SEPARATOR=\n
    ...    import { chromium } from 'playwright';
    ...    import axeCore from 'axe-core';
    ...    import fs from 'fs';
    ...    
    ...    // Parâmetros de linha de comando
    ...    const url = process.argv[2];
    ...    const outputFile = process.argv[3];
    ...    
    ...    if (!url || !outputFile) {
    ...      console.error('Uso: node script.js URL ARQUIVO_SAIDA');
    ...      process.exit(1);
    ...    }
    ...    
    ...    async function runAxe() {
    ...      console.log(`Testando acessibilidade em: ${url}`);
    ...      
    ...      // Iniciar navegador
    ...      const browser = await chromium.launch();
    ...      const context = await browser.newContext();
    ...      const page = await context.newPage();
    ...      
    ...      try {
    ...        // Navegar para a URL
    ...        await page.goto(url, { waitUntil: 'networkidle', timeout: 90000 });
    ...        console.log('Página carregada com sucesso.');
    ...        
    ...        // Injetar axe-core
    ...        await page.evaluate(() => {
    ...          if (!window.axe) {
    ...            const script = document.createElement('script');
    ...            script.text = `${axeCore.source}`;
    ...            document.head.appendChild(script);
    ...          }
    ...        });
    ...        
    ...        // Executar análise com foco em regras WCAG
    ...        const results = await page.evaluate(() => {
    ...          return new Promise((resolve) => {
    ...            axe.run({
    ...              runOnly: {
    ...                type: 'tag',
    ...                values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'best-practice']
    ...              },
    ...              resultTypes: ['violations', 'incomplete', 'inapplicable', 'passes']
    ...            }, (err, results) => {
    ...              if (err) throw err;
    ...              resolve(results);
    ...            });
    ...          });
    ...        });
    ...        
    ...        // Adicionar metadados
    ...        results.testUrl = url;
    ...        results.timestamp = new Date().toISOString();
    ...        
    ...        // Mapeamento de regras para critérios WCAG
    ...        const wcagMap = {};
    ...        results.violations.forEach(violation => {
    ...          const wcagTags = violation.tags.filter(t => t.startsWith('wcag'));
    ...          if (wcagTags.length > 0) {
    ...            wcagTags.forEach(tag => {
    ...              if (!wcagMap[tag]) {
    ...                wcagMap[tag] = [];
    ...              }
    ...              wcagMap[tag].push({
    ...                id: violation.id,
    ...                impact: violation.impact,
    ...                description: violation.help,
    ...                url: violation.helpUrl
    ...              });
    ...            });
    ...          }
    ...        });
    ...        
    ...        results.wcagMap = wcagMap;
    ...        
    ...        // Salvar resultados
    ...        fs.writeFileSync(outputFile, JSON.stringify(results, null, 2));
    ...        
    ...        // Resumo
    ...        console.log(`\nResumo da Análise de Acessibilidade:`);
    ...        console.log(`- Total de testes: ${results.passes.length + results.violations.length + results.incomplete.length}`);
    ...        console.log(`- Testes passados: ${results.passes.length}`);
    ...        console.log(`- Violações: ${results.violations.length}`);
    ...        console.log(`- Inconclusivos: ${results.incomplete.length}`);
    ...        
    ...        if (results.violations.length > 0) {
    ...          console.log(`\nTop 5 Violações WCAG:`);
    ...          results.violations.slice(0, 5).forEach((v, i) => {
    ...            const wcag = v.tags.filter(t => t.startsWith('wcag')).join(', ');
    ...            console.log(`${i+1}. ${v.id} (${wcag}) - ${v.help} - Impacto: ${v.impact}`);
    ...          });
    ...        } else {
    ...          console.log(`\nNenhuma violação WCAG encontrada!`);
    ...        }
    ...        
    ...        console.log(`\nRelatório salvo em: ${outputFile}`);
    ...        
    ...      } catch (error) {
    ...        console.error(`Erro durante teste: ${error}`);
    ...        fs.writeFileSync(outputFile, JSON.stringify({
    ...          error: error.toString(),
    ...          testUrl: url,
    ...          timestamp: new Date().toISOString()
    ...        }, null, 2));
    ...      } finally {
    ...        // Fechar navegador
    ...        await browser.close();
    ...      }
    ...    }
    ...    
    ...    runAxe().catch(console.error);
    
    # Salvar o script
    ${script_file}=    Set Variable    ${REPORT_DIR}/temp/axe_test.js
    Create File    ${script_file}    ${script_content}
    
    # Instalar dependências
    ${result}=    Run Process
    ...    cd ${REPORT_DIR}/temp && npm install
    ...    shell=True
    
    Should Be Equal As Integers    ${result.rc}    0    Falha ao instalar dependências: ${result.stderr}
    
    RETURN    ${script_file}

Process Axe Results
    [Documentation]    Processa os resultados do axe e gera relatório em Markdown
    [Arguments]    ${json_file}    ${url}    ${timestamp}
    
    # Ler o arquivo de resultados
    ${json_content}=    Get File    ${json_file}
    ${results}=    Evaluate    json.loads('''${json_content}''')    json
    
    # Criar nome do arquivo de relatório
    ${report_file}=    Set Variable    ${REPORT_DIR}/axe_report_${timestamp}.md
    
    # Iniciar conteúdo do relatório
    ${report_content}=    Catenate    SEPARATOR=\n
    ...    # Relatório de Acessibilidade WCAG
    ...    
    ...    **URL:** ${url}  
    ...    **Data do teste:** ${timestamp}
    ...    
    ...    ## Resumo
    
    # Adicionar resumo
    ${violations_count}=    Get Length    ${results['violations']}
    ${passes_count}=    Get Length    ${results['passes']}
    ${incomplete_count}=    Get Length    ${results['incomplete']}
    ${total_count}=    Evaluate    ${violations_count} + ${passes_count} + ${incomplete_count}
    
    ${report_content}=    Catenate    SEPARATOR=\n    ${report_content}
    ...    
    ...    - **Total de testes:** ${total_count}
    ...    - **Testes passados:** ${passes_count}
    ...    - **Violações:** ${violations_count}
    ...    - **Inconclusivos:** ${incomplete_count}
    ...    
    
    # Status geral
    ${status}=    Set Variable If    ${violations_count} == 0    ✅ PASSOU    ❌ FALHOU
    
    ${report_content}=    Catenate    SEPARATOR=\n    ${report_content}
    ...    **Status:** ${status}
    ...    
    ...    ## Violações de Acessibilidade
    
    # Se não houver violações
    IF    ${violations_count} == 0
        ${report_content}=    Catenate    SEPARATOR=\n    ${report_content}
        ...    
        ...    ✅ **Nenhuma violação WCAG encontrada!**
    ELSE
        # Tabela de violações
        ${report_content}=    Catenate    SEPARATOR=\n    ${report_content}
        ...    
        ...    | # | Regra | Impacto | Critérios WCAG | Descrição |
        ...    |---|-------|---------|----------------|-----------|
        
        # Para cada violação
        FOR    ${index}    ${violation}    IN ENUMERATE    @{results['violations']}
            # Filtrar tags WCAG
            ${wcag_tags}=    Evaluate    [tag for tag in $violation['tags'] if tag.startswith('wcag')]
            ${wcag_tags_str}=    Evaluate    ', '.join($wcag_tags)
            
            # Adicionar linha à tabela
            ${report_content}=    Catenate    SEPARATOR=\n    ${report_content}
            ...    | ${index + 1} | ${violation['id']} | ${violation['impact']} | ${wcag_tags_str} | ${violation['help']} |
        END
    END
    
    # Adicionar referência WCAG
    ${report_content}=    Catenate    SEPARATOR=\n    ${report_content}
    ...    
    ...    ## Referência de Critérios WCAG
    ...    
    ...    - **wcag2a**: WCAG 2.0 Nível A - Requisitos mínimos de acessibilidade
    ...    - **wcag2aa**: WCAG 2.0 Nível AA - Padrão adotado pela maioria das regulamentações
    ...    - **wcag21a**: WCAG 2.1 Nível A - Atualizações com foco em dispositivos móveis e deficiências cognitivas
    ...    - **wcag21aa**: WCAG 2.1 Nível AA - Padrão atualizado recomendado
    ...    
    ...    ## Links Úteis
    ...    
    ...    - [Entendendo as Diretrizes WCAG](https://www.w3.org/WAI/WCAG21/Understanding/)
    ...    - [Técnicas para WCAG 2.1](https://www.w3.org/WAI/WCAG21/Techniques/)
    ...    - [Checklist WCAG](https://www.w3.org/WAI/WCAG21/quickref/)
    
    # Salvar o relatório
    Create File    ${report_file}    ${report_content}
    
    RETURN    ${report_file}

Create WCAG Violations Report
    [Documentation]    Cria um relatório específico sobre violações WCAG com recomendações
    [Arguments]    ${json_file}    ${url}    ${timestamp}
    
    # Ler o arquivo de resultados
    ${json_content}=    Get File    ${json_file}
    ${results}=    Evaluate    json.loads('''${json_content}''')    json
    
    # Criar nome do arquivo de relatório
    ${wcag_report_file}=    Set Variable    ${REPORT_DIR}/wcag_violations_${timestamp}.md
    
    # Iniciar conteúdo do relatório
    ${wcag_content}=    Catenate    SEPARATOR=\n
    ...    # Violações de Critérios WCAG
    ...    
    ...    **URL:** ${url}  
    ...    **Data do teste:** ${timestamp}
    
    # Verificar se há mapeamento WCAG
    ${has_wcag_map}=    Run Keyword And Return Status
    ...    Dictionary Should Contain Key    ${results}    wcagMap
    
    IF    ${has_wcag_map}
        # Obter e organizar o mapeamento WCAG
        ${wcag_map}=    Set Variable    ${results['wcagMap']}
        ${wcag_keys}=    Get Dictionary Keys    ${wcag_map}
        ${wcag_keys_sorted}=    Sort List    ${wcag_keys}
        
        IF    ${wcag_keys_sorted}
            ${wcag_content}=    Catenate    SEPARATOR=\n    ${wcag_content}
            ...    
            ...    ## Critérios WCAG Não Atendidos
            ...    
            
            FOR    ${wcag_key}    IN    @{wcag_keys_sorted}
                # Converter wcag2aa para WCAG 2.0 AA, etc.
                ${wcag_version}=    Set Variable If
                ...    "${wcag_key}" == "wcag2a"       WCAG 2.0 Nível A
                ...    "${wcag_key}" == "wcag2aa"      WCAG 2.0 Nível AA
                ...    "${wcag_key}" == "wcag21a"      WCAG 2.1 Nível A
                ...    "${wcag_key}" == "wcag21aa"     WCAG 2.1 Nível AA
                ...    ${wcag_key}
                
                # Mapear para o número do critério
                ${wcag_number}=    Get WCAG Criterion Number    ${wcag_key}
                
                ${wcag_content}=    Catenate    SEPARATOR=\n    ${wcag_content}
                ...    
                ...    ### ${wcag_version} (${wcag_number})
                ...    
                ...    | Regra | Impacto | Descrição | Recomendação |
                ...    |-------|---------|-----------|--------------|
                
                # Listar violações para este critério
                ${violations}=    Set Variable    ${wcag_map['${wcag_key}']}
                
                FOR    ${violation}    IN    @{violations}
                    ${recomendacao}=    Get Recommendation    ${violation['id']}
                    
                    ${wcag_content}=    Catenate    SEPARATOR=\n    ${wcag_content}
                    ...    | ${violation['id']} | ${violation['impact']} | ${violation['description']} | ${recomendacao} |
                END
            END
        ELSE
            ${wcag_content}=    Catenate    SEPARATOR=\n    ${wcag_content}
            ...    
            ...    ✅ **Nenhuma violação WCAG específica encontrada!**
        END
    ELSE
        # Se não houver mapeamento WCAG
        ${wcag_content}=    Catenate    SEPARATOR=\n    ${wcag_content}
        ...    
        ...    ❓ **O mapeamento detalhado de critérios WCAG não está disponível.**
        ...    
        ...    Verifique o relatório principal para mais informações sobre violações.
    END
    
    # Adicionar recomendações gerais
    ${wcag_content}=    Catenate    SEPARATOR=\n    ${wcag_content}
    ...    
    ...    ## Recomendações Gerais para Conformidade WCAG
    ...    
    ...    1. **Alternativas de Texto**: Forneça alternativas de texto para conteúdo não textual
    ...    2. **Adaptabilidade**: Crie conteúdo que possa ser apresentado de diferentes formas
    ...    3. **Distinguível**: Torne mais fácil para os usuários ver e ouvir o conteúdo
    ...    4. **Navegável**: Proporcione maneiras de ajudar os usuários a navegar e encontrar conteúdo
    ...    5. **Legível**: Torne o texto legível e compreensível
    ...    6. **Previsível**: Faça as páginas aparecerem e funcionarem de maneiras previsíveis
    ...    7. **Assistência de Entrada**: Ajude os usuários a evitar e corrigir erros
    ...    8. **Compatível**: Maximize a compatibilidade com tecnologias assistivas
    
    # Salvar o relatório
    Create File    ${wcag_report_file}    ${wcag_content}
    
    RETURN    ${wcag_report_file}

Get WCAG Criterion Number
    [Documentation]    Converte a tag WCAG para o número do critério
    [Arguments]    ${wcag_key}
    
    ${mapping}=    Create Dictionary
    ...    wcag2a=1.1.1-4.1.2
    ...    wcag2aa=1.2.4-4.1.3
    ...    wcag21a=1.3.4-4.1.3
    ...    wcag21aa=1.3.4-4.1.3
    
    ${criterion}=    Set Variable    ${mapping["${wcag_key}"]}
    ${criterion}=    Set Variable If    "${criterion}" == "${EMPTY}"    Critério Desconhecido    ${criterion}
    
    RETURN    ${criterion}

Get Recommendation
    [Documentation]    Retorna uma recomendação para uma regra específica
    [Arguments]    ${rule_id}
    
    ${recommendations}=    Create Dictionary
    ...    "color-contrast"=Aumente o contraste entre cores de primeiro plano e fundo para pelo menos 4.5:1
    ...    "image-alt"=Adicione atributos alt descritivos a todas as imagens
    ...    "link-name"=Forneça texto descritivo para todos os links
    ...    "button-name"=Adicione texto ou aria-label a todos os botões
    ...    "label"=Associe rótulos a todos os elementos de formulário
    ...    "frame-title"=Adicione títulos descritivos a todos os frames
    ...    "html-has-lang"=Adicione o atributo lang ao elemento html
    ...    "landmark-one-main"=Inclua uma região main na página
    ...    "page-has-heading-one"=Adicione um cabeçalho h1 à página
    ...    "region"=Coloque todo o conteúdo dentro de landmarks
    
    ${recomendacao}=    Set Variable If
    ...    $recommendations.get("${rule_id}")    ${recommendations["${rule_id}"]}
    ...    Consulte a documentação para esta regra
    
    RETURN    ${recomendacao}