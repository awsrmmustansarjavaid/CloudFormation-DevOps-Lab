<?php
/*
============================================================
 Charlie Cafe - Docker Learning Application
============================================================

 File:
 application/index.php

 Purpose:
 ------------------------------------------------------------
 This is the main PHP page for the Docker learning lab.

 The purpose of this file is NOT to build the complete
 Charlie Cafe application yet.

 It is a simple test application that allows us to verify:

 1. PHP is installed inside the Docker container.
 2. PHP-FPM is running.
 3. Nginx is running.
 4. Nginx can communicate with PHP-FPM.
 5. The application files are copied into:
       /var/www/html/
 6. Docker can serve the PHP application.
 7. GitHub Actions can build and test the Docker image.

 Docker flow:

 GitHub
    |
    v
 application/index.php
    |
    v
 Dockerfile
    |
    v
 /var/www/html/index.php
    |
    v
 Nginx
    |
    v
 PHP-FPM
    |
    v
 Browser / curl

============================================================
*/

/*
------------------------------------------------------------
 PHP Test
------------------------------------------------------------

 If PHP is working correctly, this PHP code will execute
 and the result will be displayed by the web server.

 If you see the PHP source code in the browser instead of
 the result, PHP-FPM/Nginx configuration needs to be fixed.
------------------------------------------------------------
*/

$pageTitle = "Charlie Cafe - Docker Learning Lab";

/*
------------------------------------------------------------
 Get PHP version
------------------------------------------------------------

 PHP_VERSION is a built-in PHP constant.

 It allows us to verify which PHP version is running inside
 the Docker container.
------------------------------------------------------------
*/

$phpVersion = PHP_VERSION;

/*
------------------------------------------------------------
 Get current server time
------------------------------------------------------------

 This is only for demonstration and troubleshooting.

 It confirms that PHP is actually executing server-side.
------------------------------------------------------------
*/

$serverTime = date("Y-m-d H:i:s");

/*
------------------------------------------------------------
 Get server operating system information
------------------------------------------------------------

 PHP_OS_FAMILY returns information such as:

 Linux
 Windows
 Darwin

 Our Docker container should report Linux.
------------------------------------------------------------
*/

$operatingSystem = PHP_OS_FAMILY;

?>
<!DOCTYPE html>
<html lang="en">

<head>

    <!--
    ========================================================
     HTML document information
    ========================================================
    -->

    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>
        <?php echo htmlspecialchars($pageTitle); ?>
    </title>

</head>

<body>

    <!--
    ========================================================
     Charlie Cafe Header
    ========================================================
    -->

    <header>

        <h1>☕ Charlie Cafe</h1>

        <p>
            Docker Learning Lab
        </p>

    </header>


    <!--
    ========================================================
     Main Application Content
    ========================================================
    -->

    <main>

        <h2>
            Docker Application is Running
        </h2>

        <p>
            Welcome to the Charlie Cafe Docker application.
        </p>

        <p>
            This page is being served by PHP inside a Docker
            container.
        </p>


        <!--
        ====================================================
         Docker / PHP Verification
        ====================================================

         These values help us verify that the application is
         actually executing inside the container.
        ====================================================
        -->

        <section>

            <h2>
                Environment Information
            </h2>

            <p>
                <strong>PHP Version:</strong>

                <?php echo htmlspecialchars($phpVersion); ?>
            </p>

            <p>
                <strong>Operating System:</strong>

                <?php echo htmlspecialchars($operatingSystem); ?>
            </p>

            <p>
                <strong>Server Time:</strong>

                <?php echo htmlspecialchars($serverTime); ?>
            </p>

        </section>


        <!--
        ====================================================
         Docker Status
        ====================================================
        -->

        <section>

            <h2>
                Docker Status
            </h2>

            <p>
                ✅ Docker container is serving the application.
            </p>

            <p>
                ✅ PHP is executing successfully.
            </p>

            <p>
                ✅ The application file was copied into the
                Docker image.
            </p>

        </section>


        <!--
        ====================================================
         Learning Architecture
        ====================================================
        -->

        <section>

            <h2>
                Lab Architecture
            </h2>

            <pre>
GitHub
   |
   v
application/index.php
   |
   v
Dockerfile
   |
   v
Docker Image
   |
   v
Docker Container
   |
   +----------------+
   |                |
   v                v
 Nginx           PHP-FPM
   |                |
   +-------+--------+
           |
           v
      Charlie Cafe
            </pre>

        </section>


        <!--
        ====================================================
         GitHub Actions Test
        ====================================================

         Your GitHub Actions workflow will eventually test:

             curl http://localhost:8080

         If this page is returned successfully, the Docker
         HTTP test should pass.
        ====================================================
        -->

        <section>

            <h2>
                GitHub Actions
            </h2>

            <p>
                The Docker container can be tested with:
            </p>

            <pre>curl http://localhost:8080</pre>

            <p>
                If the HTTP request succeeds, the Docker job
                can continue successfully.
            </p>

        </section>

    </main>


    <!--
    ========================================================
     Footer
    ========================================================
    -->

    <footer>

        <p>
            Charlie Cafe - AWS CloudFormation & Docker Lab
        </p>

        <p>
            Beginner DevOps Learning Project
        </p>

    </footer>

</body>

</html>