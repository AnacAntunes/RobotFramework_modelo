# Robot Framework Project
Este é um projeto de automação de testes utilizando o Robot Framework. O objetivo deste projeto é fornecer uma estrutura organizada para testes de APIs, interface do usuário e outros tipos de testes funcionais.

## Estrutura do Projeto
Estrutura de pastas do projeto:

Project │ 
├── .gitignore
├── README.md
├── requirements.txt
├── tests/
│   ├── acceptance_tests/
│   ├── functional_tests/
│   ├── regression_tests/
│   ├── performance_tests/
│   ├── API_tests/
│   │   └── api_test.robot
│   ├── UI_tests/
│   │   └── ui_test.robot
│   └── suites/
│       └── smoke_tests.robot
├── resources/
│   ├── keywords/
│   │   └── custom_keywords.robot
│   ├── variables/
│   │   └── global_variables.robot
│   └── libraries/
│       └── custom_library.py
├── config/
│   └── config.yaml
├── data/
│   └── test_data.json
└── reports/
├── logs/
├── reports/
└── screenshots

## Requisitos
Certifique-se de ter o [Python](https://www.python.org/) instalado em sua máquina. Você pode instalar as dependências do projeto usando o gerenciador de pacotes `pip`. Para isso, execute o seguinte comando:

```
pip install -r requirements.txt
```

### Explicações para Cada Dependência:

**robotframework:** A versão principal do Robot Framework, que é usada para escrever e executar suas suítes de teste.
**robotframework-appiumlibrary:** Uma biblioteca para integrar o Appium dentro do Robot Framework, permitindo testes de aplicações móveis.
**Appium-Python-Client:** Client oficial para o Appium que possibilita a automação de testes em aplicativos móveis.
**robotframework-seleniumlibrary:** Caso haja necessidade de testes web, essa biblioteca fornece suporte para automação com Selenium.
**requests:** Usada para realizar requisições HTTP quando você precisa interagir com serviços web durante os testes.
**pyyaml:** Facilita a manipulação de arquivos YAML, útil especialmente para configuração.

## Execução dos Testes
Para executar os testes, utilize o seguinte comando na linha de comando na raiz do projeto:
```
robot tests/<diretório_do_teste>/<arquivo_do_teste>.robot
```
Por exemplo, para executar os testes de API, você pode usar:

```bash
robot tests/API_tests/api_test.robot
```

Os relatórios e logs da execução dos testes serão gerados na pasta reports/.


### Estrutura dos Testes
Os testes estão organizados em diferentes diretórios e arquivos de acordo com seus propósitos:

**acceptance_tests/:** Testes de aceitação do sistema.
**functional_tests/:** Testes que garantem que as funcionalidades funcionam como esperado.
**regression_tests/:** Testes que garantem que as funcionalidades existentes não são quebradas por novas alterações.
**performance_tests/:** Testes que avaliam o desempenho do sistema.
**API_tests/:** Testes específicos para as APIs do sistema.
**UI_tests/:** Testes que validam a interface do usuário.
**suites/:** Conjuntos de testes para facilitar a execução de grupos de testes relacionados.

## Contribuição
Contribuições são bem-vindas! Se você encontrar algum problema ou tiver sugestões de melhoria, sinta-se à vontade para abrir uma issue ou enviar um pull request.