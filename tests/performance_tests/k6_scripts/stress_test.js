import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 2,  // usuários virtuais
  duration: '5s',  // duração muito curta para testes CI
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% das requisições abaixo de 500ms
  },
};

export default function() {
  // Teste simples de API
  const res = http.get('https://test.k6.io/');
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'page contains welcome text': (r) => r.body.includes('Welcome to the k6.io demo site!'),
  });
  
  // Pequena pausa entre requisições
  sleep(0.5);
}