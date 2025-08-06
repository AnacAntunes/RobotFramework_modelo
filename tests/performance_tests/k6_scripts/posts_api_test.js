import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
vus: 5,
duration: '15s',
thresholds: {
http_req_duration: ['p(95)<300'],
http_req_failed: ['rate<0.005'],
},
};

export default function() {
const url = 'https://jsonplaceholder.typicode.com/posts';
let response;

response = http.get(url);

check(response, {
'status is 200 or 201': (r) => r.status === 200 || r.status === 201,
'has content': (r) => r.body.length > 0,
});

sleep(1);
}