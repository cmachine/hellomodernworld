const http = require("http");

const hostname = "0.0.0.0";
const port = 8080;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader("Content-Type", "text/plain");
  res.end("Hello Modern World");
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});

const mathOperations = {
  sum: function (a, b) {
    return a + b;
  },

  diff: function (a, b) {
    return a - b;
  },
  product: function (a, b) {
    return a * b;
  },
  divide: function (a, b) {
    return a / b;
  },
};

module.exports = mathOperations;
