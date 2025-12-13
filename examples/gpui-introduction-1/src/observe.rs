use gpui::*;

struct Counter {
    value: u32,
}

impl Counter {
    fn new() -> Self {
        Self { value: 0 }
    }

    fn increment(&mut self, cx: &mut Context<Self>) {
        self.value += 1;
        cx.notify();
    }
}

struct CounterDisplay {
    counter: Entity<Counter>,
}

impl CounterDisplay {
    fn new(counter: Entity<Counter>, cx: &mut Context<Self>) -> Self {
        cx.observe(&counter, |this, counter, cx| {
            cx.notify();
        })
        .detach();

        Self { counter }
    }
}

impl Render for CounterDisplay {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let value = self.counter.read(cx).value;
        div()
            .child(format!("Counter value: {}", value))
            .child(div().child("Button").on_mouse_down(
                MouseButton::Left,
                cx.listener(|this, _evt, _window, cx| {
                    this.counter.update(cx, |counter, cx| {
                        counter.increment(cx);
                    });
                }),
            ))
    }
}

pub fn start() {
    let app = Application::new();
    app.run(move |cx| {
        cx.spawn(async move |cx| {
            cx.open_window(WindowOptions::default(), |window, cx| {
                cx.new(|cx| CounterDisplay::new(cx.new(|cx| Counter::new()), cx))
            })?;
            Ok::<_, anyhow::Error>(())
        })
        .detach();
    });
}
