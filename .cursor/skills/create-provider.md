# Create Provider

Quando solicitado:

Create Provider <Nome>

Criar um Provider utilizando Riverpod.

## Gerar

- Provider
- State
- Notifier (quando necessário)
- Integração com UseCases
- Tratamento de Loading
- Tratamento de Erro
- Tratamento de Sucesso
- Testes Unitários

## Sempre verificar

- O Provider nunca acessa APIs diretamente.
- O Provider comunica apenas com UseCases.
- Não colocar regra de negócio no Provider.
- Estados devem ser previsíveis.

Sempre utilizar Riverpod seguindo boas práticas.
