# 🔧 App Facing Microservices

Build a Microservices platform with multi-gradle Spring Boot for easy integration across multiple applications. Provide a shared foundation for internal projects, allowing extension with additional common services and app-specific services in production.

## 📁 Modules

- [Communication](./communication) – Manages real-time chat, private messaging, and channel subscriptions. Built with WebSocket or Redis pub/sub for scalable delivery.

- [Order Lifecycle](./order-lifecycle) – Manages the full lifecycle of orders, including creation, validation, status tracking, updates, and completion. Ensures consistency across inventory, billing, and notifications while supporting asynchronous processing and event-driven triggers.
  
  + [Checkout](./checkout)
    
  + [Payment](./payment)
 
Each module is independently runnable and documented in its own README.md file.

---

### 🛠 Contribute

If you’d like to contribute or share your code, **do not commit directly to 'main'**

Please create a new branch using the allowed proper prefixes: **feature/** , **bugfix/** , **hotfix/** , **dev/** , **release/**

#### ⚠️ If you don’t use a proper prefix, your branch might not be protected and could be modified by others

Then open a Pull Request (PR) to merge into 'main'

#### ➡️ All changes will be reviewed before merging, use meaningful branch names and commit messages

---

### ⚖️ License:
This repository is licensed under the **MIT** License

---

### 🧑‍💻 Author:
[William Phan](https://github.com/wliamp)

---

### 📫 Contact:
`phnam230197@gmail.com`

