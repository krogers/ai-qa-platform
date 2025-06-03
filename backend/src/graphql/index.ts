import { makeExecutableSchema } from '@graphql-tools/schema';
import { GraphQLScalarType } from 'graphql/type';
import { Kind } from 'graphql/language';
import { GraphQLJSON } from 'graphql-type-json';
import { resolvers } from './resolvers';
import { typesSchema, querySchema, mutationSchema } from './schemas';

const typeDefs = [typesSchema, querySchema, mutationSchema].join('\n');

const DateScalar = new GraphQLScalarType({
  name: 'Date',
  description: 'Date custom scalar type',
  serialize(value: any) {
    if (value instanceof Date) {
      return value.toISOString();
    }
    throw new Error('Value is not an instance of Date: ' + value);
  },
  parseValue(value: any) {
    if (typeof value === 'string') {
      return new Date(value);
    }
    throw new Error('Value is not a valid date string: ' + value);
  },
  parseLiteral(ast) {
    if (ast.kind === Kind.STRING) {
      return new Date(ast.value);
    }
    throw new Error('Can only parse strings to dates but got a: ' + ast.kind);
  },
});

const UUIDScalar = new GraphQLScalarType({
  name: 'UUID',
  description: 'UUID custom scalar type',
  serialize(value: any) {
    if (typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)) {
      return value;
    }
    throw new Error('Value is not a valid UUID: ' + value);
  },
  parseValue(value: any) {
    if (typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)) {
      return value;
    }
    throw new Error('Value is not a valid UUID: ' + value);
  },
  parseLiteral(ast) {
    if (ast.kind === Kind.STRING && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(ast.value)) {
      return ast.value;
    }
    throw new Error('Can only parse strings to UUIDs but got a: ' + ast.kind);
  },
});

const scalarResolvers = {
  Date: DateScalar,
  UUID: UUIDScalar,
  JSON: GraphQLJSON,
};

export const schema = makeExecutableSchema({
  typeDefs,
  resolvers: {
    ...scalarResolvers,
    ...resolvers,
  },
});