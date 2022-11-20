export const handler = async (event) => {
  console.log(event)

  return {
    statusCode: 200,
    body: JSON.stringify({ message: 'Hello from Lambda!' }),
    headers: {
      'content-type': 'application/json'
    }
  }
}
