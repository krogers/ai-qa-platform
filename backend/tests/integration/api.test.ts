import { handler } from '@/lambdas/api-handler';
import { APIGatewayProxyEvent, Context } from 'aws-lambda';

describe('API Handler Integration', () => {
  const mockContext: Context = {
    callbackWaitsForEmptyEventLoop: false,
    functionName: 'test-function',
    functionVersion: '1',
    invokedFunctionArn: 'arn:aws:lambda:us-east-1:123456789012:function:test-function',
    memoryLimitInMB: '512',
    awsRequestId: 'test-request-id',
    logGroupName: '/aws/lambda/test-function',
    logStreamName: '2023/01/01/[$LATEST]test-stream',
    getRemainingTimeInMillis: () => 30000,
    done: jest.fn(),
    fail: jest.fn(),
    succeed: jest.fn(),
  };

  it('should handle health check query', async () => {
    const event: APIGatewayProxyEvent = {
      body: JSON.stringify({
        query: 'query { health }'
      }),
      headers: {
        'Content-Type': 'application/json'
      },
      httpMethod: 'POST',
      path: '/graphql',
      pathParameters: null,
      queryStringParameters: null,
      stageVariables: null,
      requestContext: {
        accountId: '123456789012',
        apiId: 'test-api',
        httpMethod: 'POST',
        path: '/graphql',
        protocol: 'HTTP/1.1',
        requestId: 'test-request',
        requestTime: '01/Jan/2023:00:00:00 +0000',
        requestTimeEpoch: 1672531200000,
        resourceId: 'test-resource',
        resourcePath: '/graphql',
        stage: 'test',
        identity: {
          accessKey: null,
          accountId: null,
          apiKey: null,
          apiKeyId: null,
          caller: null,
          clientCert: null,
          cognitoAuthenticationProvider: null,
          cognitoAuthenticationType: null,
          cognitoIdentityId: null,
          cognitoIdentityPoolId: null,
          principalOrgId: null,
          sourceIp: '127.0.0.1',
          user: null,
          userAgent: 'test-agent',
          userArn: null,
        },
        authorizer: null,
      },
      resource: '/graphql',
      isBase64Encoded: false,
      multiValueHeaders: {},
      multiValueQueryStringParameters: null,
    };

    const result = await handler(event, mockContext, jest.fn());

    expect(result).toMatchObject({
      statusCode: 200,
      headers: expect.objectContaining({
        'Content-Type': 'application/json',
      }),
    });

    const body = JSON.parse(result.body || '{}');
    expect(body.data?.health).toBe('OK');
  });

  it('should handle GraphQL introspection in development', async () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';

    const event: APIGatewayProxyEvent = {
      body: JSON.stringify({
        query: `
          query IntrospectionQuery {
            __schema {
              queryType {
                name
              }
            }
          }
        `
      }),
      headers: {
        'Content-Type': 'application/json'
      },
      httpMethod: 'POST',
      path: '/graphql',
      pathParameters: null,
      queryStringParameters: null,
      stageVariables: null,
      requestContext: {
        accountId: '123456789012',
        apiId: 'test-api',
        httpMethod: 'POST',
        path: '/graphql',
        protocol: 'HTTP/1.1',
        requestId: 'test-request',
        requestTime: '01/Jan/2023:00:00:00 +0000',
        requestTimeEpoch: 1672531200000,
        resourceId: 'test-resource',
        resourcePath: '/graphql',
        stage: 'test',
        identity: {
          accessKey: null,
          accountId: null,
          apiKey: null,
          apiKeyId: null,
          caller: null,
          clientCert: null,
          cognitoAuthenticationProvider: null,
          cognitoAuthenticationType: null,
          cognitoIdentityId: null,
          cognitoIdentityPoolId: null,
          principalOrgId: null,
          sourceIp: '127.0.0.1',
          user: null,
          userAgent: 'test-agent',
          userArn: null,
        },
        authorizer: null,
      },
      resource: '/graphql',
      isBase64Encoded: false,
      multiValueHeaders: {},
      multiValueQueryStringParameters: null,
    };

    const result = await handler(event, mockContext, jest.fn());

    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body || '{}');
    expect(body.data?.__schema?.queryType?.name).toBe('Query');

    process.env.NODE_ENV = originalEnv;
  });
});