*** Settings ***
Documentation     Teste de acessibilidade baseado em critérios WCAG
Library           Process
Library           OperatingSystem
Library           Collections
Library           DateTime
Library           String

*** Variables ***
${REPORT_DIR}         ${CURDIR}/../../reports/accessibility
# Sites reais para testar
${SITES_TO_TEST}      https://www.gov.br/    https://www.w3.org/WAI/    https://www.example.com/

*** Test Cases ***
Verificar Conformidade WCAG
    [Documentation]    Executa testes de acessibilidade validando critérios WCAG
    [Tags]    accessibility    wcag
    
    # Criar diretório para relatórios
    Create Directory    ${REPORT_DIR}
    
    # Obter timestamp para arquivos únicos
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    
    # Criar script Node.js para testar acessibilidade com axe-core
    ${script_path}=    Create Axe Test Script
    
    # Executar script para cada site
    FOR    ${site}    IN    @{SITES_TO_TEST}
        ${site_name}=    Convert URL To Filename    ${site}
        ${output_file}=    Set Variable    ${REPORT_DIR}/${site_name}_${timestamp}.json
        
        ${result}=    Run Process    node ${script_path} ${site} ${output_file}    shell=True
        
        # Verificar execução do script
        Should Be Equal As Integers    ${result.rc}    0    Falha ao executar teste para ${site}: ${result.stderr}
        
        # Processar resultados
        ${violations}=    Process WCAG Violations    ${output_file}    ${site}
        
        # Criar relatório resumido
        Create Summary Report    ${site}    ${violations}    ${timestamp}
    END
    
    Log    Testes de conformidade WCAG concluídos para todos os sites.

*** Keywords ***
Convert URL To Filename
    [Documentation]    Converte URL em um nome de arquivo válido
    [Arguments]    ${url}
    
    ${filename}=    Replace String    ${url}    http://    
    ${filename}=    Replace String    ${filename}    https://    
    ${filename}=    Replace String    ${filename}    /    _
    ${filename}=    Replace String    ${filename}    :    _
    ${filename}=    Replace String    ${filename}    .    -
    
    RETURN    ${filename}

Create Axe Test Script
    [Documentation]    Cria um script Node.js para testar acessibilidade com axe-core
    
    # Criar um diretório temporário para o script
    Create Directory    ${REPORT_DIR}/temp
    
    # Criar package.json
    ${package_json}=    Catenate    SEPARATOR=\n
    ...    {
    ...      "name": "wcag-axe-test",
    ...      "version": "1.0.0",
    ...      "description": "WCAG accessibility testing script",
    ...      "main": "axe-test.js",
    ...      "dependencies": {
    ...        "axe-core": "^4.7.0",
    ...        "puppeteer": "^20.7.4"
    ...      }
    ...    }
    
    Create File    ${REPORT_DIR}/temp/package.json    ${package_json}
    
    # Criar script de teste
    ${test_script}=    Catenate    SEPARATOR=\n
    ...    const puppeteer = require('puppeteer');
    ...    const axeCore = require('axe-core');
    ...    const fs = require('fs');
    ...    const path = require('path');
    ...    
    ...    // URL para testar é passada como argumento
    ...    const url = process.argv[2];
    ...    const outputFile = process.argv[3];
    ...    
    ...    if (!url) {
    ...      console.error('URL não fornecida. Use: node axe-test.js URL OUTPUT_FILE');
    ...      process.exit(1);
    ...    }
    ...    
    ...    async function runTest() {
    ...      console.log(`Testando acessibilidade WCAG em: ${url}`);
    ...      
    ...      // Iniciar navegador
    ...      const browser = await puppeteer.launch({
    ...        args: ['--no-sandbox', '--disable-setuid-sandbox'],
    ...        headless: 'new'
    ...      });
    ...      
    ...      try {
    ...        const page = await browser.newPage();
    ...        
    ...        // Navegar para a página
    ...        await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
    ...        
    ...        // Injetar axe-core
    ...        await page.evaluateHandle(`
    ...          ${axeCore.source}
    ...        `);
    ...        
    ...        // Executar teste axe com foco em WCAG 2.1 AA
    ...        const results = await page.evaluate(() => {
    ...          return new Promise(resolve => {
    ...            axe.run({
    ...              runOnly: {
    ...                type: 'tag',
    ...                values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']
    ...              }
    ...            }, (err, results) => {
    ...              if (err) throw err;
    ...              resolve(results);
    ...            });
    ...          });
    ...        });
    ...        
    ...        // Adicionar metadados
    ...        results.url = url;
    ...        results.timestamp = new Date().toISOString();
    ...        
    ...        // Salvar resultados
    ...        fs.writeFileSync(outputFile, JSON.stringify(results, null, 2));
    ...        
    ...        console.log(`Teste concluído. Relatório salvo em: ${outputFile}`);
    ...        console.log(`Violações encontradas: ${results.violations.length}`);
    ...        
    ...        // Mostrar resumo das violações
    ...        if (results.violations.length > 0) {
    ...          console.log('\nResumo das violações WCAG:');
    ...          results.violations.forEach((violation, index) => {
    ...            console.log(`\n${index + 1}. ${violation.id} - ${violation.help}`);
    ...            console.log(`   Impacto: ${violation.impact}`);
    ...            console.log(`   Critério WCAG: ${violation.tags.filter(t => t.startsWith('wcag')).join(', ')}`);
    ...          });
    ...        } else {
    ...          console.log('\nNenhuma violação WCAG encontrada!');
    ...        }
    ...        
    ...      } catch (error) {
    ...        console.error(`Erro ao testar ${url}:`, error);
    ...        
    ...        // Salvar informação de erro
    ...        fs.writeFileSync(outputFile, JSON.stringify({
    ...          error: error.toString(),
    ...          url: url,
    ...          timestamp: new Date().toISOString()
    ...        }, null, 2));
    ...        
    ...      } finally {
    ...        await browser.close();
    ...      }
    ...    }
    ...    
    ...    runTest().catch(console.error);
    
    Create File    ${REPORT_DIR}/temp/axe-test.js    ${test_script}
    
    # Instalar dependências
    ${install_result}=    Run Process
    ...    cd ${REPORT_DIR}/temp && npm install
    ...    shell=True
    
    Should Be Equal As Integers    ${install_result.rc}    0    Falha ao instalar dependências: ${install_result.stderr}
    
    RETURN    ${REPORT_DIR}/temp/axe-test.js

Process WCAG Violations
    [Documentation]    Processa violações WCAG do arquivo de resultados
    [Arguments]    ${results_file}    ${url}
    
    # Verificar se o arquivo existe
    File Should Exist    ${results_file}    Arquivo de resultados não encontrado: ${results_file}
    
    # Ler arquivo JSON
    ${json_content}=    Get File    ${results_file}
    ${results}=    Evaluate    json.loads('''${json_content}''')    json
    
    # Verificar se há violações
    ${has_violations}=    Run Keyword And Return Status
    ...    Dictionary Should Contain Key    ${results}    violations
    
    ${violations}=    Set Variable    @{EMPTY}
    
    IF    ${has_violations}
        ${violations}=    Set Variable    ${results['violations']}
        ${count}=    Get Length    ${violations}
        Log    ${count} violações WCAG encontradas em ${url}
    ELSE
        ${has_error}=    Run Keyword And Return Status
        ...    Dictionary Should Contain Key    ${results}    error
        
        IF    ${has_error}
            Log    Erro durante o teste de ${url}: ${results['error']}
        ELSE
            Log    Nenhuma violação WCAG encontrada em ${url}
        END
    END
    
    RETURN    ${violations}

Create Summary Report
    [Documentation]    Cria um relatório resumido das violações WCAG
    [Arguments]    ${url}    ${violations}    ${timestamp}
    
    ${site_name}=    Convert URL To Filename    ${url}
    ${report_file}=    Set Variable    ${REPORT_DIR}/wcag_summary_${site_name}_${timestamp}.md
    
    # Iniciar conteúdo do relatório
    ${report_content}=    Catenate    SEPARATOR=\n
    ...    # Relatório de Conformidade WCAG
    ...    
    ...    **URL:** ${url}  
    ...    **Data e hora:** ${timestamp}
    ...    
    ...    ## Resumo das Violações
    
    ${violations_count}=    Get Length    ${violations}
    
    IF    ${violations_count} == 0
        ${report_content}=    Catenate    SEPARATOR=\n    ${report_content}
        ...    
        ...    ✅ **Nenhuma violação WCAG encontrada!**
    ELSE
        ${report_content}=    Catenate    SEPARATOR=\n    ${report_content}
        ...    
        ...    ❌ **${violations_count} violações WCAG encontradas**
        ...    
        ...    | # | Regra | Impacto | Critérios WCAG | Descrição |
        ...    |---|-------|---------|----------------|-----------|
        
        FOR    ${index}    ${violation}    IN ENUMERATE    @{violations}
            # Filtrar tags WCAG
            ${wcag_tags}=    Evaluate    [tag for tag in $violation['tags'] if tag.startswith('wcag')]
            ${wcag_tags_str}=    Evaluate    ', '.join($wcag_tags)
            
            # Adicionar linha à tabela
            ${report_content}=    Catenate    SEPARATOR=\n    ${report_content}
            ...    | ${index + 1} | ${violation['id']} | ${violation['impact']} | ${wcag_tags_str} | ${violation['help']} |
        END
    END
    
    # Adicionar detalhes sobre critérios WCAG
    ${report_content}=    Catenate    SEPARATOR=\n    ${report_content}
    ...    
    ...    ## Referência de Critérios WCAG
    ...    
    ...    - **wcag2a**: WCAG 2.0 Nível A
    ...    - **wcag2aa**: WCAG 2.0 Nível AA
    ...    - **wcag21a**: WCAG 2.1 Nível A
    ...    - **wcag21aa**: WCAG 2.1 Nível AA
    ...    
    ...    Para mais informações sobre os critérios WCAG, visite: [WCAG Overview](https://www.w3.org/WAI/standards-guidelines/wcag/)
    
    # Salvar relatório
    Create File    ${report_file}    ${report_content}
    
    Log    Relatório de conformidade WCAG criado para ${url}: ${report_file}