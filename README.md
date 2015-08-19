QuickNote - Turn out notes on a dime
=========

A commandline application to manage your notes.

Inspired by [todo.sh](https://github.com/ginatrapani/todo.txt-cli).

## Getting Started ##

-   **Install**

    ```
    git clone https://github.com/bsmith89/quicknote.git
    cd quicknote
    ln -s quicknote /somewhere/in/your/PATH
    ```

-   **Customize**

    ```
    cp quicknote.cfg ~/.quicknote.cfg
    # edit .quicknote.cfg
    # put new/overriding actions into ~/.quicknote.addons.d
    ```

-   **Bootstrap**

    ```
    quicknote bootstrap
    ```

-   **Add remote**

    ```
    quicknote git remote add origin [url]
    quicknote push -u origin master
    ```

-   **Get help**

    ```
    quicknote help
    ```

## Requirements ##

-   `git`
-   `bash`

### (Planned) Features ###

-   [x] Archive notes
-   [x] Identify notes with only a unique prefix
-   [x] Doctor: diagnose problems
-   [x] Bootstrap setup
-   [x] Git integration
-   [x] Help system
-   [x] Easily customizable and extensible
-   [ ] Documentation (90% there)
-   [ ] Bash completion
-   [ ] Prettier grep output
-   [ ] Speed optimization
-   [ ] Add README.md example note to bootstrapped setups
-   [ ] Name the process correctly on `quicknote edit`
