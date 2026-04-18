const String getProductsQuery = r'''
  query GetProducts {
    products {
      id
      name
      price
      createdAt
    }
  }
''';

const String addProductMutation = r'''
  mutation AddProduct($name: String!, $price: Float!) {
    addProduct(name: $name, price: $price) {
      id
      name
      price
      createdAt
    }
  }
''';

const String updateProductMutation = r'''
  mutation UpdateProduct($id: ID!, $name: String!, $price: Float!) {
    updateProduct(id: $id, name: $name, price: $price) {
      id
      name
      price
      createdAt
    }
  }
''';

const String deleteProductMutation = r'''
  mutation DeleteProduct($id: ID!) {
    deleteProduct(id: $id)
  }
''';

const String getUsersQuery = r'''
  query GetUsers {
    users {
      id
      firstName
      lastName
      createdAt
    }
  }
''';

const String createUserMutation = r'''
  mutation CreateUser($firstName: String!, $lastName: String!) {
    createUser(firstName: $firstName, lastName: $lastName) {
      id
      firstName
      lastName
      createdAt
    }
  }
''';

const String updateUserMutation = r'''
  mutation UpdateUser($id: ID!, $firstName: String!, $lastName: String!) {
    updateUser(id: $id, firstName: $firstName, lastName: $lastName) {
      id
      firstName
      lastName
      createdAt
    }
  }
''';

const String deleteUserMutation = r'''
  mutation DeleteUser($id: ID!) {
    deleteUser(id: $id)
  }
''';

const String getRecordsQuery = r'''
  query GetRecords {
    records {
      id
      user {
        id
        firstName
        lastName
        createdAt
      }
      product {
        id
        name
        price
        createdAt
      }
      quantity
      createdAt
    }
  }
''';

const String addRecordsMutation = r'''
  mutation AddRecords($userId: ID!, $items: [RecordInput!]!) {
    addRecords(userId: $userId, items: $items)
  }
''';
