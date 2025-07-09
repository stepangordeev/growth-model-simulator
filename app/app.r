library(shiny)
library(tibble)
library(dplyr)
library(plotly)
library(bslib)
library(fontawesome)
if (FALSE) {
    # explicitly tell shiny about the munsell dependency, otherwise shinylive fails
    library(munsell)
}

Y <- function(A, K, X, L_y, gamma, alpha, beta) {
    A^gamma * K^alpha * X^beta * L_y^(1 - alpha - beta)
}

K_lom <- function(K, I_y, delta) {
    K * (1 - delta) + I_y
}

A_lom <- function(A, I_a) {
    A + I_a
}

L_lom <- function(L, b0, d0, d1, y) {
    L * (1 + b0 - d0 + d1 * y)
}

I_y <- function(Y, s) {
    s * Y
}

I_a <- function(A, K, L_a, z, phi, theta) {
    z * A^(phi) * K^(theta) * L_a^(1 - theta)
}


# build dataframe period by period

simulate <- function(
        L_1 = 1,
        K_1 = 1,
        A_1 = 1,
        alpha = 0,
        beta = 0,
        gamma = 1,
        delta = 0,
        phi = 0,
        theta = 0,
        b0 = 0,
        d0 = 0,
        d1 = 0,
        z = 0,
        s = 0,
        a = 0, # researcher share
        X = 1,
        T = 200
    ) {
    df <- tibble(
        period = 1:T,
        Y = numeric(T),
        A = numeric(T),
        K = numeric(T),
        L = numeric(T),
        I_y = numeric(T),
        I_a = numeric(T),
        C = numeric(T),
        y = numeric(T),
        k = numeric(T),
        x = numeric(T),
        c = numeric(T),
        g_Y = numeric(T),
        g_y = numeric(T),
        g_A = numeric(T),
        g_K = numeric(T),
        g_k = numeric(T),
        g_L = numeric(T),
        g_C = numeric(T),
        g_c = numeric(T)
    )
    df$L[1] <- L_1
    df$K[1] <- K_1
    df$A[1] <- A_1
    df$Y[1] <- Y(df$A[1], df$K[1], X, df$L[1]*(1-a), gamma, alpha, beta)
    df$I_y[1] <- I_y(df$Y[1], s)
    df$I_a[1] <- I_a(df$A[1], df$K[1], df$L[1]*a, z, phi, theta)
    df$C[1] <- df$Y[1] - df$I_y[1]
    df$y[1] <- df$Y[1] / df$L[1]
    df$k[1] <- df$K[1] / df$L[1]
    df$x[1] <- X / df$L[1]
    df$c[1] <- df$C[1] / df$L[1]
    for (t in 1:(T-1)) {
        df$A[t+1] <- A_lom(df$A[t], df$I_a[t])
        df$L[t+1] <- L_lom(df$L[t], b0, d0, d1, df$y[t])
        df$K[t+1] <- K_lom(df$K[t], df$I_y[t], delta)
        df$Y[t+1] <- Y(df$A[t+1], df$K[t+1], X, df$L[t+1]*(1-a), gamma, alpha, beta)
        df$I_y[t+1] <- I_y(df$Y[t+1], s)
        df$I_a[t+1] <- I_a(df$A[t+1], df$K[t+1], df$L[t+1]*a, z, phi, theta)
        df$C[t+1] <- df$Y[t+1] - df$I_y[t+1]
        df$c[t+1] <- df$C[t+1] / df$L[t+1]
        df$y[t+1] <- df$Y[t+1] / df$L[t+1]
        df$k[t+1] <- df$K[t+1] / df$L[t+1]
        df$x[t+1] <- X / df$L[t+1]
        df$g_Y[t+1] <- (df$Y[t+1] - df$Y[t]) / df$Y[t]
        df$g_A[t+1] <- (df$A[t+1] - df$A[t]) / df$A[t]
        df$g_K[t+1] <- (df$K[t+1] - df$K[t]) / df$K[t]
        df$g_L[t+1] <- (df$L[t+1] - df$L[t]) / df$L[t]
        df$g_y[t+1] <- (df$y[t+1] - df$y[t]) / df$y[t]
        df$g_k[t+1] <- (df$k[t+1] - df$k[t]) / df$k[t]
        df$g_C[t+1] <- (df$C[t+1] - df$C[t]) / df$C[t]
        df$g_c[t+1] <- (df$c[t+1] - df$c[t]) / df$c[t]
    }
    return(df)
}

# Solow
df_solow <- simulate(
    alpha = 0.33,
    delta = 0.1,
    s = 0.3
)

# Malthus
df_malthus <- simulate(
    K = 0,
    beta = 0.33,
    b0 = 0.01,
    d0 = 0.1,
    d1 = 0.1
)

df_romer <- simulate(
    alpha = 0.33,
    delta = 0.1,
    s = 0.3,
    z = 0.01,
    a = 0.2,
    phi = 1
)

df_jones <- simulate(
    alpha = 0.33,
    delta = 0.1,
    s = 0.3,
    z = 0.01,
    a = 0.2,
    phi = 0,
    gamma = 0.2,
    b0 = 0.01,
    T = 1000
)

df_jones_ai <- simulate(
    alpha = 0.33,
    delta = 0.1,
    s = 0.3,
    z = 0.01,
    a = 0.2,
    phi = 0.5,
    gamma = 1,
    theta = 0.9,
    T = 1000
)


sidebar_accordion <- accordion(
    accordion_panel(
        "Production Function",
        icon = fa("hammer"),
        sliderInput("alpha", withMathJax("\\(\\alpha\\) (capital share)"), value = 0.3, min = 0, max = 1, step = 0.1),
        sliderInput("beta", withMathJax("\\(\\beta\\) (land share)"), value = 0.3, min = 0, max = 1, step = 0.1),
        sliderInput("gamma", withMathJax("\\(\\gamma\\) (TFP returns to scale)"), value = 1, min = 0, max = 1, step = 0.1)
    ),
    accordion_panel(
        "Capital Dynamics",
        icon = fa("industry"),
        sliderInput("delta", withMathJax("\\(\\delta\\) (depreciation rate)"), value = 0.1, min = 0, max = 1, step = 0.1),
        sliderInput("s", withMathJax("\\(s\\) (savings rate)"), value = 0.3, min = 0, max = 1, step = 0.1)
    ),
    accordion_panel(
        "Population Dynamics",
        icon = fa("baby-carriage"),
        sliderInput("b0", withMathJax("\\(b_0\\) (birth rate)"), value = 0, min = 0, max = 1, step = 0.1),
        sliderInput("d0", withMathJax("\\(d_0\\) (death rate intercept)"), value = 0, min = 0, max = 1, step = 0.1),
        sliderInput("d1", withMathJax("\\(d_1\\) (death rate slope w.r.t. \\(y\\))"), value = 0, min = 0, max = 1, step = 0.1)
    ),
    accordion_panel(
        "TFP Dynamics",
        icon = fa("flask"),
        sliderInput("z", withMathJax("\\(z\\) (research productivity)"), value = 0, min = 0, max = 10, step = 1),
        sliderInput("phi", withMathJax("\\(\\phi\\) (research returns to scale)"), value = 0, min = 0, max = 1, step = 0.1),
        sliderInput("theta", withMathJax("\\(\\theta\\) (research automation)"), value = 0, min = 0, max = 1, step = 0.1),
        sliderInput("a", withMathJax("\\(a\\) (researcher share)"), value = 0, min = 0, max = 1, step = 0.1)
    ),
    accordion_panel(
        "Initial Values",
        icon = fa("rocket"),
        sliderInput("K_1", withMathJax("\\(K_1\\) (initial capital)"), value = 1, min = 1, max = 10, step = 1),
        sliderInput("L_1", withMathJax("\\(L_1\\) (initial labor)"), value = 1, min = 1, max = 10, step = 1),
        sliderInput("A_1", withMathJax("\\(A_1\\) (initial TFP)"), value = 1, min = 1, max = 10, step = 1),
        sliderInput("X", withMathJax("\\(X\\) (permanent land)"), value = 1, min = 1, max = 10, step = 1)
    ),
    accordion_panel(
        "Simulation Settings",
        icon = fa("gamepad"),
        sliderInput("T", withMathJax("\\(T\\) (number of periods)"), value = 200, min = 50, max = 500, step = 50)
    )
)

panel_graph_width = "500px"
layout_column_wrap_plots <- function(...) {
    # for each passed plot name, create a card with plotlyOutput, compose them into a layout_column_wrap with globally defined width
    plot_names <- list(...)
    cards <- lapply(plot_names, function(plot_name) {
        card(
            plotlyOutput(plot_name)
        )
    })
    do.call(
        layout_column_wrap,
        c(list(width = panel_graph_width), cards)
    )
}

aggregates_panel <- layout_column_wrap_plots(
    "Y_plot",
    "A_plot",
    "K_plot",
    "L_plot",
    "C_plot"
)
per_capita_panel <- layout_column_wrap_plots(
    "y_plot",
    "k_plot",
    "x_plot",
    "c_plot"
)
growth_aggregates_panel <- layout_column_wrap_plots(
    "g_Y_plot",
    "g_A_plot",
    "g_K_plot",
    "g_L_plot",
    "g_C_plot"
)
growth_per_capita_panel <- layout_column_wrap_plots(
    "g_y_plot",
    "g_k_plot",
    "g_c_plot"
)


ui <- page_sidebar(
    sidebar = sidebar(
        title = "Parameters",
        sidebar_accordion
    ),
    navset_pill(
        nav_panel(title = "Aggregates", aggregates_panel),
        nav_panel(title = "Per Capita", per_capita_panel),
        nav_panel(title = "Growth: Aggregates", growth_aggregates_panel),
        nav_panel(title = "Growth: Per Capita", growth_per_capita_panel),
        nav_panel(title = "Table", 
            # using the "EDIT" solution from https://stackoverflow.com/a/54762876 to render table with mathjax: other approaches didn't work
            uiOutput("table_test")
        )
    )
)


render_plot_ly_simul <- function(simulation, y_col, title) {
    # have to pass reactive()'s output (simulation) as a variable and then invoke it as a function here (simulation()), otherwise the graph won't update
    renderPlotly({
        plot_ly(simulation(), x = ~period, y = as.formula(paste0("~", y_col)), type = 'scatter', mode = 'lines') |>
        layout(
            title = TeX(title),
            xaxis = list(title = "Period"),
            yaxis = list(title = "")
        ) |>
        config(
            mathjax = "cdn"
        )
    })
}

server <- function(input, output, session) {
    simulation <- reactive(simulate(
        L_1 = input$L_1,
        K_1 = input$K_1,
        A_1 = input$A_1,
        alpha = input$alpha,
        beta = input$beta,
        gamma = input$gamma,
        delta = input$delta,
        phi = input$phi,
        theta = input$theta,
        b0 = input$b0,
        d0 = input$d0,
        d1 = input$d1,
        z = input$z,
        s = input$s,
        a = input$a,
        X = input$X
    ))
    output$dynamic <- renderTable(
        {
            simulation() |>
            rename_with(
                ~ paste0("$$", .x, "$$")
            )
        },
        include.colnames = TRUE,
        striped = TRUE,
        digits = 3
    )
    output$table_test <- renderUI(
        # using the "EDIT" solution from https://stackoverflow.com/a/54762876 to render table with mathjax: other approaches didn't work
        tagList(
            withMathJax(),
            withMathJax(
                tableOutput("dynamic")
            )
        )
    )
    output$Y_plot <- render_plot_ly_simul(simulation, "Y", "Y")
    output$A_plot <- render_plot_ly_simul(simulation, "A", "A")
    output$K_plot <- render_plot_ly_simul(simulation, "K", "K")
    output$L_plot <- render_plot_ly_simul(simulation, "L", "L")
    output$C_plot <- render_plot_ly_simul(simulation, "C", "C")
    output$g_Y_plot <- render_plot_ly_simul(simulation, "g_Y", "g_Y")
    output$g_A_plot <- render_plot_ly_simul(simulation, "g_A", "g_A")
    output$g_K_plot <- render_plot_ly_simul(simulation, "g_K", "g_K")
    output$g_L_plot <- render_plot_ly_simul(simulation, "g_L", "g_L")
    output$g_C_plot <- render_plot_ly_simul(simulation, "g_C", "g_C")
    output$g_y_plot <- render_plot_ly_simul(simulation, "g_y", "g_y")
    output$g_k_plot <- render_plot_ly_simul(simulation, "g_k", "g_k")
    output$g_c_plot <- render_plot_ly_simul(simulation, "g_c", "g_c")
    output$x_plot <- render_plot_ly_simul(simulation, "x", "x")
    output$k_plot <- render_plot_ly_simul(simulation, "k", "k")
    output$y_plot <- render_plot_ly_simul(simulation, "y", "y")
    output$c_plot <- render_plot_ly_simul(simulation, "c", "c")
}
shinyApp(ui, server)