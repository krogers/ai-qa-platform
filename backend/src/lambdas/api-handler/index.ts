import { APIGatewayProxyEvent, APIGatewayProxyResult, Context, Handler } from 'aws-lambda';
import { ApolloServer } from '@apollo/server';
import { startServerAndCreateLambdaHandler, handlers } from '@as-integrations/aws-lambda';
import { GraphQLError } from 'graphql/error';
import { v4 as uuidv4 } from 'uuid';
import { schema } from '@/graphql';
import { validateConfig } from '@/config';
import { logger } from '@/utils/logger';
import { AppError } from '@/utils/errors';
import { GraphQLContext } from '@/types';

validateConfig();

const server = new ApolloServer<GraphQLContext>({
  schema,
  formatError: (error: GraphQLError) => {
    logger.error('GraphQL error', { error: error.message, stack: error.stack });

    if (error.originalError instanceof AppError) {
      return {
        message: error.message,
        code: error.originalError.statusCode,
        path: error.path,
      };
    }

    if (process.env.NODE_ENV === 'prod') {
      return {
        message: 'Internal server error',
        code: 500,
      };
    }

    return {
      message: error.message,
      locations: error.locations,
      path: error.path,
    };
  },
  introspection: process.env.NODE_ENV !== 'prod',
  plugins: [
    {
      async requestDidStart() {
        return {
          async willSendResponse(requestContext: any) {
            if (requestContext.response.http?.headers) {
              requestContext.response.http.headers.set('Access-Control-Allow-Origin', '*');
              requestContext.response.http.headers.set('Access-Control-Allow-Headers', 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token');
              requestContext.response.http.headers.set('Access-Control-Allow-Methods', 'GET,OPTIONS,POST,PUT');
            }
          },
        };
      },
    },
  ],
});

export const handler = startServerAndCreateLambdaHandler(
  server,
  handlers.createAPIGatewayProxyEventRequestHandler()
);