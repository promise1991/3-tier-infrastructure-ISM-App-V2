# Inventory Management System MERN CRUD App
A simple MERN project that lets the user insert, update, delete & get products from the MongoDB.

#### 📌 Recommended Production Deployment Approach
- We’ll split this into sections:
- Directory & Deployment Structure
- MongoDB Setup
- Backend Setup (Node + Express)
- Frontend Setup (React)
- Nginx Reverse Proxy (optional but highly recommended for production)
- Process Management (PM2) for backend
- Security & Production Practices

## Steps To Implements In Your Server

1. 📌**Clone the original repo** from (https://github.com/mhy20401/Inventory-Management-System-MERN-CRUD-App)

   ```BASH 
   git clone https://github.com/mhy20401/Inventory-Management-System-MERN-CRUD-App.git Inventory-Management-System

   cd Inventory-Management-System
   ```
2. 📌(***Optionally***) **Make few modifications to the folder structure**
```bash
mv Frontend/inventory_management_system/* Frontend/ 
rm -rf Frontend/inventory_management_system
```
The plan is to have a folder structure such as this below:
- `.env` file on both the `Frontend` and `Backend` Directories
- `log` folder in the root directory<br>
*See the folder structure of the project below:*

### 📌**Project Structure**

```
📁 Inventory-Management-System/

├── Frontend/
│   ├── 📁 build/
│   ├── package.json
│   ├── package-lock.json
│   ├── .env
│   ├── public/
│   └── 📁 src/
│       ├── App.js
│       ├── index.js
│       ├── 📁 Others files and folders
|
├── Backend/
│   ├── package.json
│   ├── package-lock.json
│   ├── .env
│   ├── index.js
│   ├── db.js
│   ├── 📁 Models/
|   └── 📁 Routes
├── README.md
└── logs/
    ├── backend.log
    ├── frontend_access.log
    ├── frontend_error.log

```

### 📌**MongoDB Setup**

- **Install MongoDB**
   ```bash
   sudo apt update
   sudo apt install -y mongodb
   sudo systemctl enable mongodb
   sudo systemctl start mongodb

   ```
- **Secure MongoDB** (*Bind to localhost only (default in `/etc/mongodb.conf`)*)

- **Create user and Database**
   - Run `mongosh` or `mongosh "mongodb://localhost:27017"` 
   - Run `use IMS` to create a Database called `IMS`
   - Enter the following to create a user with username `ims_admin` password `StrongPasswordHere` and assign role `readWrite` tothe database `IMS`
      ```bash
         db.createUser({
         user: "ims_admin",
         pwd: "StrongPasswordHere",
         roles: [ { role: "readWrite", db: "IMS" } ]
         })
      ```
   - Type `exit` and click *Enter* key to exit the DB
      ```bash
      IMG> exit
      ```
   - **Update** the `Backend/.env` file with our new connection string in this format
   `mongodb://127.0.0.1:27017/<database-name>` or `mongodb://localhost:27017/<database-name>`

      ```bash
       MONGO_URI=mongodb://127.0.0.1:27017/IMS
      ```
   
      *Note that this connection is locally - that is the DB and the app are in the same server, so they can connect locally. if the db is in a different server*<br>
      
      ```bash
      MONGO_URI=mongodb://ims_admin:StrongPasswordHere@127.0.0.1:27017/IMS
      ```
### 📌Firewall Setup
Ensure you have enabled firewall and allow port              
Nginx Full                 ALLOW       Anywhere #for nginx
Nginx Full (v6)            ALLOW       Anywhere (v6) # for nginx
8000/tcp (v6)              ALLOW       Anywhere (v6)  # for backend
3000 (v6)                  ALLOW       Anywhere (v6)  # for frontend

Run:
- `sudo ufw status` to confirm it is it inactive or active
- `sudo ufw enable` to make it active
- `sudo ufw allow OpenSSH`
- `sudo ufw allow 'Nginx Full'`
- `sudo ufw enable <port>` to Allow incoming traffic on a specific port
   - Example: `sudo ufw allow 8000/tcp` to allows access to port 8000
   - Do the same for others
- `sudo ufw reload` to reload rules

For cloud VM, expost these port on the Netword security group, most especially the 443 for SSL 

### 📌Backend Setup
- **Install Node & PM2**
   ```bash
   sudo apt install -y nodejs npm
   sudo npm install -g pm2
   ```
- **Create** .env file for sensitive config and update it with the configuration below
   ```text
   MONGO_URI=mongodb://127.0.0.1:27017/IMS
   PORT=8000
   ```
-  **Update** your `Backend/db.js` to read from `.env`
   ```javascript
   require('dotenv').config();
   const mongoose = require('mongoose');

   const connectToMongo = async () => {
   try {
      mongoose.set("strictQuery", false);
      await mongoose.connect(process.env.MONGO_URI);
      console.log("Connected to Mongo Successfully!");
   } catch (error) {
      console.error("MongoDB Connection Error:", error);
   }
   };

   module.exports = connectToMongo;
   ```

- **Update** the `Backend/index.js` file to read from `.env`
   ```javascript
   require('dotenv').config(); // Load environment variables from config
   const connectToMongo = require('./db')
   connectToMongo();

   const express = require('express')
   const app = express()
   const port = process.env.PORT || 8000; // Default port if MONGO_URI is not set

   const cors = require('cors')
   const router = require('./Routes/router')

   app.use(cors());
   app.use(express.json());
   app.use('/api', router); // i am adding /api/something because i want the nginx to handing it via proxy and not missing it up with frontend

  app.listen(port, '0.0.0.0', () => { // '0.0.0.0' this for access from other ends
   console.log(`Example app listening on port ${port}`);
   });
   ```
   here i replaced  `const port = process.env.PORT || 8000;` to pick from .env file and the `app.listen(port, () => {});` so that Node can listen on all network interfaces, not just localhost.

   
- **Navigate** to `Backend` Directory and run `npm install`<br>
  Add   `"dotenv": "^16.5.0",` in the package.json file so we can use `.env` file
   ```bash
   cd /path-to-Backend/backend
   npm install
   ```

- **Start backend with PM2**
   ```text
   pm2 start index.js --name ims-backend
   pm2 save
   pm2 startup
   ```
   You will see something like this the screenshot1 to confirm that the backend is running

- **Test backend**  
   - `curl http://localhost:8000` will give error `Cannot GET /`
   - `curl http://localhost:8000/api/products` will produce `[]` showing no records in the DB



### 📌Frontend Setup(without Nginx)

- **Add your backend URL** to `frontend/.env`
   ```bash
   REACT_APP_API_BASE_URL=http://20.4.221.14:8000/api
   ```
- **Update** the `/Frontend/src/components/InsertProduct.js`,`/Frontend/src/components/UpdateProduct.js`, and `/Frontend/src/components/Products.js` files.<br>

   Replace the `http://localhost:3001` in `http://localhost:3001/products` and other endpoints  with `${process.env.REACT_APP_API_BASE_URL}` so we can have smething like  `${process.env.REACT_APP_API_BASE_URL}/products`

   Note: Replace every double-quote with backtick "`" in the full path(see my example in the updated files)

- **Test locally** to confirm that it works
   ``` Bash
   cd Frontend
   npm install
   npm start
   ```
   Test on browser with our IP `<YOUR-PN>:3000`<br>
   Test on terminal `curl http://<YOUR-PN>:3000`<br>
   See screenshot 2

### 📌Frontend Setup(with Nginx)
We will serve React files via Nginx

- **Install Nginx**
   ```bash
   sudo apt install nginx
   sudo systemctl enable nginx
   sudo systemctl start nginx
   ```

- **Build React production files**
   ```bash
   cd Frontend
   npm run build
   ```
   A new folder `build` will be available for us to use in production

- **Move content** of `Frondent/build/` to `/var/www/<your-domain-url>/html` director
   - Create a directory in `/var/www` e.g. `/var/www/prince-opah.name.ng/html`
   - Copy the content of `Frondent/build/` to `/var/www/prince-opah.name.ng/html`
   - confirm that the content are in `/var/www/prince-opah.name.ng/html`

   ```bash
   sudo mkdir -p /var/www/prince-opah.name.ng/html
   sudo cp -r build/* /var/www/prince-opah.name.ng/html
   sudo ls /var/www/prince-opah.name.ng/html
   ```
   Note: I assume you are in `/Frontend` directory

- **Configure Nginx:**
   - Create a file in `/etc/nginx/sites-available` e.g `/etc/nginx/sites-available/prince-opah.name.ng`
      - Run `sudo vi /etc/nginx/sites-available/prince-opah.name.ng`
      - Enter the settings:
      ```BASH
      server {
               listen 80;
               server_name prince-opah.name.ng www.prince-opah.name.ng; # add your domain or your VM/VPS IP here.

               root /var/www/prince-opah.name.ng/html;    # this is where the files are and should be looked for
               index index.html;    # look for file with this format 

               location / {
                  try_files $uri /index.html;
               }

               error_log /var/log/nginx/prince-opah.name.ng_error.log;
               access_log /var/log/nginx/prince-opah.name.ng_error.log;

               location /api/ {
                  proxy_pass http://127.0.0.1:8000/api/;
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection 'upgrade';
                  proxy_set_header Host $host;
                  proxy_cache_bypass $http_upgrade;
               }
            }
      ```
   - `root` handles the part `/var/www/prince-opah.name.ng/html` that we move the build content to
   - `prince-opah.name.ng` and `www.prince-opah.name.ng` are my test domain and subdomain, respectively

- **Creates a symbolic link**<br> 
   Nginx looks for configuration files in the sites-enabled directory by default. This is because the nginx package is configured to include the sites-enabled directory in its default configuration.

   - Creates a symbolic link between ` /etc/nginx/sites-available/<your-configuration-file>` and ` /etc/nginx/sites-enabled`
   - Test if the configurtion is valid:<BR>
       After validating with `sudo nginx -t`, you will get something like:<br>
      `nginx: the configuration file /etc/nginx/nginx.conf syntax is ok`<br>
      `nginx: configuration file /etc/nginx/nginx.conf test is successful`
   - Reload your nginx(if if it initially running) or restart if it was stopped
   ```bash 
   sudo ln -s /etc/nginx/sites-available/prince-opah.name.ng /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```
   Note: `prince-opah.name.ng` is the name of my configuration file. pls choose yours

### 📌Install SSL (Let's Encrypt) with Certbot
   ###### Install Certbot and Nginx plugin: `sudo apt install certbot python3-certbot-nginx -y`
   ##### Obtain SSL certificate: `sudo certbot --nginx -d prince-opah.name.ng -d www.prince-opah.name.ng`
      § Follow the prompts: 
         □ Enter your email for renewal notices.
         □ Agree to terms.
         □ Choose to redirect HTTP to HTTPS (recommended for security).
      § Certbot will: 
         □ Obtain a certificate.
         □ Modify your Nginx config to use HTTPS.(see screenshot below)
         □ Set up auto-renewal.
         □ info such as the following will be provided upon successful setup
            Successfully received certificate.
            Certificate is saved at: /etc/letsencrypt/live/prince-opah.name.ng/fullchain.pem
            Key is saved at:         /etc/letsencrypt/live/prince-opah.name.ng/privkey.pem
            This certificate expires on 2025-09-05.
            These files will be updated when the certificate renews.
            Certbot has set up a scheduled task to automatically renew this certificate in the background.
            
            Deploying certificate
            Successfully deployed certificate for prince-opah.name.ng to /etc/nginx/sites-enabled/prince-opah.name.ng
            Successfully deployed certificate for www.prince-opah.name.ng to /etc/nginx/sites-enabled/prince-opah.name.ng
Congratulations! You have successfully enabled HTTPS on https://prince-opah.name.ng and https://www.prince-opah.name.ng

You can now access the SSL enabled sites(see screenshotd)

- Final result of my nginx configuration after cartbot:
```Javascript
server {
    server_name prince-opah.name.ng www.prince-opah.name.ng;

    root /var/www/prince-opah.name.ng/html;
    index index.html;

    # Serve frontend routes
    location / {
        try_files $uri /index.html;
    }

    # Proxy backend requests
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/prince-opah.name.ng/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/prince-opah.name.ng/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    listen 80;
    server_name prince-opah.name.ng www.prince-opah.name.ng;
    return 301 https://$host$request_uri;
}

```

---
The Project explaination
📖 Who's doing what right now:

✅ PM2
   - Is running the Node.js backend app (on localhost:8000)
   - it Keeps the backend alive
   - It’s not serving to the public directly — Nginx sits in front.

✅ Nginx
   - Nginx serves the React static files directly for `/` using: 
      ```
         location / {   # Serve React frontend
            try_files $uri /index.html;
         }
      ```
   - Is acting as a reverse proxy for the backend. Nginx proxies only /api/ (or whatever prefix that we choose) to the PM2-managed backend at localhost:8000
   - Right now, all requests to https://prince-opah.name.ng/api/ are forwarded to the - backend via:

- This way:
   - https://prince-opah.name.ng/products → shows the React app
   - https://prince-opah.name.ng/api/products → proxies to PM2 backend

✅ After this:
   - https://prince-opah.name.ng will serve our React frontend
   - React frontend will request APIs at https://prince-opah.name.ng/api/products
   - Nginx will proxy /api/ to your Node backend on localhost:8000
   - so there is no need to expose port 8000 publicly
   - Clean, secure, and production-grade

<br>
<br>

---

### To Troubleshoot
- Run `pm2 logs <servce-name>` o see the logs
- Stop the pm2 process and test manually `pm2 stop ims-backend` and run `node index` 

### Improvements


## Images

![alt text](<./README-ASSETS/pm2.PNG>)

![Alt text](./README-ASSETS/frontend-IP.PNG)

![Local image](./README-ASSETS/domain.PNG)
![Local image](./README-ASSETS/homepage.PNG)
![Local image](./README-ASSETS/ssl.PNG)
![Local image](./README-ASSETS/backend-api.PNG)


