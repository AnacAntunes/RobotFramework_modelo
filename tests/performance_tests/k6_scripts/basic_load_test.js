import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

// Métricas personalizadas
const errors = new Counter('errors');
const successRate = new Rate('successful_requests');

// Configurações do teste
export const options = {
  // Estas podem ser sobrescritas pela linha de comando
  vus: 10,
  duration: '30s',
  
  // Limiares de qualidade
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% das requisições devem ser < 500ms
    'http_req_failed': ['rate<0.01'],  // Taxa de erro < 1%
    'successful_requests': ['rate>0.95'],  // Taxa de sucesso > 95%
  },
};

// Função principal de teste
export default function() {
  // Teste GET
  const getResponse = http.get('https://jsonplaceholder.typicode.com/posts');
  
  const getChecks = check(getResponse, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
    'response body not empty': (r) => r.body.length > 0,
  });
  
  successRate.add(getChecks);
  
  if (!getChecks) {
    errors.add(1);
    console.log(`Falha no GET: ${getResponse.status}, duração: ${getResponse.timings.duration}ms`);
  }
  
  // Teste POST
  const payload = JSON.stringify({
    title: 'foo',
    body: 'bar',
    userId: 1
  });
  
  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };
  
  const postResponse = http.post('https://jsonplaceholder.typicode.com/posts', payload, params);
  
  const postChecks = check(postResponse, {
    'status is 201': (r) => r.status === 201,
    'has id': (r) => r.json().id !== undefined,
  });
  
  successRate.add(postChecks);
  
  if (!postChecks) {
    errors.add(1);
    console.log(`Falha no POST: ${postResponse.status}, duração: ${postResponse.timings.duration}ms`);
  }
  
  // Pausa para simular comportamento real de usuário
  sleep(Math.random() * 2 + 1); // Entre 1-3 segundos
}