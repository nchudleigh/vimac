# Metrics Collection

As of v0.3.17 (28), Vimac collects usage metrics so that I (@dexterleng) can make data-informed decisions regarding the application going into the future.

I've written this document to be transparent about what data I'll be collecting and how they will be used.

## Usage Metrics Collected

Vimac reports the following events:

1. Hint Mode Activated/Deactivated/Action Performed/Hint Rotation
2. Scroll Mode Activated/Deactivated/Cycle Scroll Area

## What are the metrics collected used for?

### 1. Optimizing the Vimac workflow

Vimac is an application that aims to help you replace the mouse/trackpad with the keyboard. I would like to measure the retention rate (percentage of users that continue using Vimac after n-days). This would help in determining:

1. The difficulty users have replacing the mouse with the keyboard with Vimac
2. Whether a change I've made to the workflow has reduced that difficulty

### 2. Improving the algorithm for determining "hintability"

I've attached the target application's bundle identifier to events. This allows me to determine:

1. The common applications Vimac is used on
2. The applications Vimac do not work well on

Vimac's algorithm for determining whether an element is "hintable" is largely dependent on heuristics based on patterns I've observed in applications I've tested it on. Knowing about the popular target applications allows me to prioritize testing and improving the experience when using Vimac on those applications.

## What we will not track

Vimac will not report the contents of the screen that it has access to through the Accessibility API.

## Privacy

No login is required to use Vimac. Usage metrics are anonymous and the identity of the user cannot be determined.

## Can I disable usage metrics reporting?

No. I will make it optional in v1.
