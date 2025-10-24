import { createFileRoute } from '@tanstack/react-router'

const App = () => {
  return (
    <main>
      Decentralized File Storagenpm
    </main>
  )
}

const Route = createFileRoute('/')({
  component: App,
})

export { Route };
